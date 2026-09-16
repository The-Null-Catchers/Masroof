<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\V1\AccountResource;
use App\Http\Resources\V1\CategoryResource;
use App\Http\Resources\V1\TransactionResource;
use App\Models\Account;
use App\Models\Category;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletingScope;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;

/**
 * Incremental pull for offline-first clients.
 *
 * Clients send the `server_time` from their previous pull as `since` and
 * receive every record created, updated, or deleted after it. Writes are
 * pushed through the regular resource endpoints using client-generated ULIDs.
 */
class SyncController extends Controller
{
    private const LIMIT = 1000;

    public function pull(Request $request): JsonResponse
    {
        $request->validate(['since' => ['sometimes', 'nullable', 'date']]);

        // Captured before querying so nothing written during the pull is skipped next time.
        $serverTime = now();
        $since = $request->filled('since') ? Carbon::parse($request->input('since')) : null;
        $user = $request->user();

        [$accounts, $moreAccounts] = $this->changes($user->accounts(), $since);
        [$categories, $moreCategories] = $this->changes($user->categories(), $since);
        [$transactions, $moreTransactions] = $this->changes($user->transactions()->with(['transferAccount', 'tags']), $since);

        $hasMore = $moreAccounts || $moreCategories || $moreTransactions;
        $cursor = $hasMore
            ? collect([$accounts, $categories, $transactions])->flatten()->max('updated_at')
            : $serverTime;

        return response()->json([
            'server_time' => $cursor->toIso8601String(),
            'has_more' => $hasMore,
            'accounts' => $this->split($accounts, AccountResource::class, $request),
            'categories' => $this->split($categories, CategoryResource::class, $request),
            'transactions' => $this->split($transactions, TransactionResource::class, $request),
        ]);
    }

    /**
     * @param  HasMany<covariant Account|Category|Transaction, User>  $relation
     * @return array{0: \Illuminate\Database\Eloquent\Collection<int, covariant Account|Category|Transaction>, 1: bool}
     */
    private function changes(HasMany $relation, ?Carbon $since): array
    {
        $rows = $relation->withoutGlobalScope(SoftDeletingScope::class)
            ->when($since, fn ($q) => $q->where('updated_at', '>', $since))
            ->orderBy('updated_at')
            ->limit(self::LIMIT + 1)
            ->get();

        return [$rows->take(self::LIMIT), $rows->count() > self::LIMIT];
    }

    /**
     * @param  Collection<int, mixed>  $rows
     * @param  class-string<JsonResource>  $resource
     * @return array{upserted: mixed, deleted: array<int, string>}
     */
    private function split($rows, string $resource, Request $request): array
    {
        [$deleted, $live] = $rows->partition(fn ($row) => $row->deleted_at !== null);

        return [
            'upserted' => $resource::collection($live->values())->toArray($request),
            'deleted' => $deleted->pluck('id')->values()->all(),
        ];
    }
}
