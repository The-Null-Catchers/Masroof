<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\TransactionType;
use App\Http\Controllers\Concerns\ResolvesClientIds;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\TransactionRequest;
use App\Http\Resources\V1\TransactionResource;
use App\Models\Transaction;
use App\Services\TransactionService;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\Rule;

class TransactionController extends Controller
{
    use ResolvesClientIds;

    public function __construct(private readonly TransactionService $service) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        $filters = $request->validate([
            'type' => ['sometimes', Rule::enum(TransactionType::class)],
            'account_id' => ['sometimes', 'ulid'],
            'category_id' => ['sometimes', 'ulid'],
            'from' => ['sometimes', 'date'],
            'to' => ['sometimes', 'date', 'after_or_equal:from'],
            'search' => ['sometimes', 'string', 'max:100'],
            'merchant' => ['sometimes', 'string', 'max:120'],
            'min_amount' => ['sometimes', 'numeric', 'min:0'],
            'max_amount' => ['sometimes', 'numeric', 'min:0'],
            'tags' => ['sometimes', 'array', 'max:10'],
            'tags.*' => ['ulid'],
            'payment_method' => ['sometimes', Rule::in(config('masroof.payment_methods'))],
            'sort' => ['sometimes', Rule::in(['occurred_at', '-occurred_at', 'amount', '-amount'])],
            'per_page' => ['sometimes', 'integer', 'between:1,100'],
        ]);

        $sort = $filters['sort'] ?? '-occurred_at';
        $direction = str_starts_with($sort, '-') ? 'desc' : 'asc';

        $transactions = $request->user()->transactions()
            ->with(['account', 'transferAccount', 'category', 'tags'])
            ->when($filters['type'] ?? null, fn (Builder $q, string $type) => $q->where('type', $type))
            ->when($filters['account_id'] ?? null, fn (Builder $q, string $id) => $q->where(
                fn (Builder $q) => $q->where('account_id', $id)->orWhere('transfer_account_id', $id)
            ))
            ->when($filters['category_id'] ?? null, fn (Builder $q, string $id) => $q->where(
                fn (Builder $q) => $q->where('category_id', $id)
                    ->orWhereIn('category_id', fn ($sub) => $sub->select('id')->from('categories')->where('parent_id', $id))
            ))
            ->when($filters['from'] ?? null, fn (Builder $q, string $from) => $q->where('occurred_at', '>=', Carbon::parse($from)->utc()))
            ->when($filters['to'] ?? null, fn (Builder $q, string $to) => $q->where('occurred_at', '<=', $this->endOf($to)))
            ->when($filters['search'] ?? null, fn (Builder $q, string $search) => $this->search($q, $search))
            ->when($filters['merchant'] ?? null, fn (Builder $q, string $merchant) => $q->whereLike('merchant', addcslashes($merchant, '%_\\')))
            ->when(isset($filters['min_amount']), fn (Builder $q) => $q->whereRaw($this->majorAmountSql().' >= ?', [$filters['min_amount']]))
            ->when(isset($filters['max_amount']), fn (Builder $q) => $q->whereRaw($this->majorAmountSql().' <= ?', [$filters['max_amount']]))
            ->when($filters['tags'] ?? null, fn (Builder $q, array $tags) => $q->whereHas('tags', fn (Builder $t) => $t->whereIn('tags.id', $tags)))
            ->when($filters['payment_method'] ?? null, fn (Builder $q, string $method) => $q->where('payment_method', $method))
            ->orderBy(ltrim($sort, '-'), $direction)
            ->orderBy('id', $direction)
            ->paginate($filters['per_page'] ?? 25)
            ->withQueryString();

        return TransactionResource::collection($transactions);
    }

    public function store(TransactionRequest $request): JsonResponse
    {
        if ($existing = $this->existingClientRecord($request, Transaction::class)) {
            return (new TransactionResource($existing->load(['account', 'transferAccount', 'category', 'tags'])))->response();
        }

        $transaction = $this->service->create($request->user(), $request->toAttributes());

        return (new TransactionResource($transaction->load(['account', 'transferAccount', 'category', 'tags'])))
            ->response()
            ->setStatusCode(201);
    }

    public function show(Transaction $transaction): TransactionResource
    {
        Gate::authorize('view', $transaction);

        return new TransactionResource($transaction->load(['account', 'transferAccount', 'category', 'tags']));
    }

    public function update(TransactionRequest $request, Transaction $transaction): TransactionResource
    {
        Gate::authorize('update', $transaction);

        $data = $request->toAttributes();
        unset($data['id']);
        $transaction = $this->service->update($transaction, $data);

        return new TransactionResource($transaction->load(['account', 'transferAccount', 'category', 'tags']));
    }

    public function destroy(Transaction $transaction): JsonResponse
    {
        Gate::authorize('delete', $transaction);

        $this->service->delete($transaction);

        return response()->json(null, 204);
    }

    public function duplicate(Request $request, Transaction $transaction): JsonResponse
    {
        Gate::authorize('view', $transaction);
        $request->validate(['occurred_at' => ['sometimes', 'date']]);

        abort_if($transaction->account()->value('archived_at') !== null, 422, __('masroof.account_archived'));

        $copy = $this->service->duplicate(
            $transaction,
            $request->filled('occurred_at') ? Carbon::parse($request->input('occurred_at'))->utc() : null,
        );

        return (new TransactionResource($copy->load(['account', 'transferAccount', 'category', 'tags'])))
            ->response()
            ->setStatusCode(201);
    }

    /**
     * Matches merchant, note, category name, tag name, or an exact amount
     * when the term is numeric.
     *
     * @param  Builder<Transaction>  $query
     */
    private function search(Builder $query, string $search): void
    {
        $term = '%'.addcslashes($search, '%_\\').'%';
        $like = DB::getDriverName() === 'pgsql' ? 'ilike' : 'like';
        $amount = str_replace(',', '', $search);

        $query->where(function (Builder $q) use ($term, $like, $amount) {
            $q->where('merchant', $like, $term)
                ->orWhere('note', $like, $term)
                ->orWhereHas('category', fn (Builder $c) => $c->where('name', $like, $term))
                ->orWhereHas('tags', fn (Builder $t) => $t->where('name', $like, $term));

            if (is_numeric($amount)) {
                $q->orWhereRaw($this->majorAmountSql().' = ?', [$amount]);
            }
        });
    }

    /** SQL expression converting minor units to major units per currency. */
    private function majorAmountSql(): string
    {
        /** @var array<string, int> $currencies */
        $currencies = config('masroof.currencies');
        $cases = collect($currencies)
            ->map(fn (int $exp, string $code) => "WHEN '{$code}' THEN ".(10 ** $exp))
            ->implode(' ');

        return "(transactions.amount::numeric / (CASE transactions.currency {$cases} ELSE 100 END))";
    }

    /** A date-only `to` filter includes the whole day. */
    private function endOf(string $to): Carbon
    {
        $date = Carbon::parse($to);

        return preg_match('/^\d{4}-\d{2}-\d{2}$/', $to) ? $date->endOfDay()->utc() : $date->utc();
    }
}
