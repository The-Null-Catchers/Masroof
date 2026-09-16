<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Concerns\ResolvesClientIds;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\AccountRequest;
use App\Http\Resources\V1\AccountResource;
use App\Models\Account;
use App\Services\TransactionService;
use App\Support\Money;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;

class AccountController extends Controller
{
    use ResolvesClientIds;

    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate(['include_archived' => ['sometimes', 'boolean']]);

        $accounts = $request->user()->accounts()
            ->when(! $request->boolean('include_archived'), fn ($q) => $q->whereNull('archived_at'))
            ->orderBy('sort_order')
            ->orderBy('created_at')
            ->get();

        return AccountResource::collection($accounts);
    }

    public function store(AccountRequest $request): JsonResponse
    {
        if ($existing = $this->existingClientRecord($request, Account::class)) {
            return (new AccountResource($existing))->response();
        }

        $account = $request->user()->accounts()->make($request->toAttributes());
        if ($request->filled('id')) {
            $account->id = $request->input('id');
        }
        $account->balance = $account->opening_balance;
        $account->archived_at = $request->boolean('archived') ? now() : null;
        $account->save();

        return (new AccountResource($account))->response()->setStatusCode(201);
    }

    public function show(Account $account): AccountResource
    {
        Gate::authorize('view', $account);

        return new AccountResource($account);
    }

    public function update(AccountRequest $request, Account $account, TransactionService $service): AccountResource
    {
        Gate::authorize('update', $account);

        DB::transaction(function () use ($request, $account, $service) {
            $account->fill($request->toAttributes());
            if ($request->has('archived')) {
                $account->archived_at = $request->boolean('archived') ? ($account->archived_at ?? now()) : null;
            }
            $account->save();

            if ($account->wasChanged('opening_balance')) {
                $service->recalculate($account);
            }
        });

        return new AccountResource($account->refresh());
    }

    public function destroy(Account $account): JsonResponse
    {
        Gate::authorize('delete', $account);

        DB::transaction(function () use ($account) {
            // Transfers touching other accounts must be unwound so their balances stay correct.
            $service = app(TransactionService::class);
            $account->incomingTransfers()->each(fn ($t) => $service->delete($t));
            $account->transactions()->where('type', 'transfer')->each(fn ($t) => $service->delete($t));
            $account->transactions()->delete();
            $account->delete();
        });

        return response()->json(null, 204);
    }

    public function summary(Request $request): JsonResponse
    {
        $user = $request->user();
        $totals = $user->accounts()->toBase()
            ->whereNull('archived_at')
            ->where('include_in_total', true)
            ->groupBy('currency')
            ->selectRaw('currency, SUM(balance) AS total, COUNT(*) AS accounts')
            ->get()
            ->map(fn ($row) => [
                'currency' => $row->currency,
                'total' => Money::toDecimal((int) $row->total, $row->currency),
                'total_minor' => (int) $row->total,
                'accounts' => (int) $row->accounts,
            ])
            ->values();

        return response()->json(['data' => ['net_worth' => $totals]]);
    }
}
