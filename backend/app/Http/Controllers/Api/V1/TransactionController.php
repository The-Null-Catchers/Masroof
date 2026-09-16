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
            'sort' => ['sometimes', Rule::in(['occurred_at', '-occurred_at', 'amount', '-amount'])],
            'per_page' => ['sometimes', 'integer', 'between:1,100'],
        ]);

        $sort = $filters['sort'] ?? '-occurred_at';
        $direction = str_starts_with($sort, '-') ? 'desc' : 'asc';

        $transactions = $request->user()->transactions()
            ->with(['account', 'transferAccount', 'category'])
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
            ->when($filters['search'] ?? null, function (Builder $q, string $search) {
                $term = '%'.addcslashes($search, '%_\\').'%';
                $q->where(fn (Builder $q) => $q->whereLike('payee', $term)->orWhereLike('note', $term));
            })
            ->orderBy(ltrim($sort, '-'), $direction)
            ->orderBy('id', $direction)
            ->paginate($filters['per_page'] ?? 25)
            ->withQueryString();

        return TransactionResource::collection($transactions);
    }

    public function store(TransactionRequest $request): JsonResponse
    {
        if ($existing = $this->existingClientRecord($request, Transaction::class)) {
            return (new TransactionResource($existing->load(['account', 'transferAccount', 'category'])))->response();
        }

        $transaction = $this->service->create($request->user(), $request->toAttributes());

        return (new TransactionResource($transaction->load(['account', 'transferAccount', 'category'])))
            ->response()
            ->setStatusCode(201);
    }

    public function show(Transaction $transaction): TransactionResource
    {
        Gate::authorize('view', $transaction);

        return new TransactionResource($transaction->load(['account', 'transferAccount', 'category']));
    }

    public function update(TransactionRequest $request, Transaction $transaction): TransactionResource
    {
        Gate::authorize('update', $transaction);

        $data = $request->toAttributes();
        unset($data['id']);
        $transaction = $this->service->update($transaction, $data);

        return new TransactionResource($transaction->load(['account', 'transferAccount', 'category']));
    }

    public function destroy(Transaction $transaction): JsonResponse
    {
        Gate::authorize('delete', $transaction);

        $this->service->delete($transaction);

        return response()->json(null, 204);
    }

    /** A date-only `to` filter includes the whole day. */
    private function endOf(string $to): Carbon
    {
        $date = Carbon::parse($to);

        return preg_match('/^\d{4}-\d{2}-\d{2}$/', $to) ? $date->endOfDay()->utc() : $date->utc();
    }
}
