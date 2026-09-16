<?php

namespace App\Services;

use App\Models\User;
use App\Support\Period;
use Carbon\CarbonImmutable;
use Illuminate\Database\Query\Builder;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

/**
 * Deterministic analytics for one currency at a time. Money in different
 * currencies is never converted or summed together.
 */
class AnalyticsService
{
    private function base(User $user, string $currency, Period $period): Builder
    {
        return DB::table('transactions')
            ->where('transactions.user_id', $user->id)
            ->whereNull('transactions.deleted_at')
            ->where('transactions.currency', $currency)
            ->where('transactions.occurred_at', '>=', $period->start)
            ->where('transactions.occurred_at', '<', $period->end);
    }

    /** @return array{income: int, expense: int} */
    public function totals(User $user, string $currency, Period $period): array
    {
        $row = $this->base($user, $currency, $period)
            ->selectRaw("COALESCE(SUM(CASE WHEN type = 'income' THEN amount END), 0) AS income, COALESCE(SUM(CASE WHEN type = 'expense' THEN amount END), 0) AS expense")
            ->first();

        return ['income' => (int) $row->income, 'expense' => (int) $row->expense];
    }

    /**
     * Expense totals per top-level category.
     *
     * @return Collection<string, covariant array<string, mixed>>
     */
    public function expensesByCategory(User $user, string $currency, Period $period): Collection
    {
        return $this->base($user, $currency, $period)
            ->where('transactions.type', 'expense')
            ->leftJoin('categories as c', 'c.id', '=', 'transactions.category_id')
            ->leftJoin('categories as p', 'p.id', '=', 'c.parent_id')
            ->selectRaw('COALESCE(p.id, c.id) AS category_id, COALESCE(p.name, c.name) AS name, COALESCE(p.default_key, c.default_key) AS default_key,
                COALESCE(p.color, c.color) AS color, COALESCE(p.icon, c.icon) AS icon, BOOL_OR(COALESCE(c.is_fixed, false) OR COALESCE(p.is_fixed, false)) AS is_fixed,
                SUM(transactions.amount) AS total, COUNT(*) AS count')
            ->groupByRaw('1, 2, 3, 4, 5')
            ->orderByDesc('total')
            ->get()
            ->mapWithKeys(fn ($row) => [(string) ($row->category_id ?? 'uncategorized') => [
                'category_id' => $row->category_id,
                'name' => $row->name,
                'default_key' => $row->default_key,
                'color' => $row->color,
                'icon' => $row->icon,
                'is_fixed' => (bool) $row->is_fixed,
                'total' => (int) $row->total,
                'count' => (int) $row->count,
            ]]);
    }

    /**
     * Full analytics for a period compared with the previous one.
     *
     * @return array<string, mixed>
     */
    public function summary(User $user, string $currency, Period $period, ?CarbonImmutable $now = null): array
    {
        $now ??= CarbonImmutable::now();
        $previous = $period->previous();
        $current = $this->totals($user, $currency, $period);
        $before = $this->totals($user, $currency, $previous);

        $categories = $this->expensesByCategory($user, $currency, $period);
        $previousCategories = $this->expensesByCategory($user, $currency, $previous);

        $elapsedDays = $period->contains($now)
            ? $period->days($user->timezone) - $period->daysLeft($user->timezone, $now) + 1
            : $period->days($user->timezone);

        $fixed = $categories->where('is_fixed', true)->sum('total');

        return [
            'currency' => $currency,
            'period' => $period->toArray($user->timezone),
            'previous_period' => $previous->toArray($user->timezone),
            'income' => $current['income'],
            'expense' => $current['expense'],
            'savings' => $current['income'] - $current['expense'],
            'savings_rate' => $this->rate($current['income'] - $current['expense'], $current['income']),
            'average_daily_spending' => intdiv($current['expense'], max(1, $elapsedDays)),
            'previous' => [
                'income' => $before['income'],
                'expense' => $before['expense'],
                'savings' => $before['income'] - $before['expense'],
                'savings_rate' => $this->rate($before['income'] - $before['expense'], $before['income']),
            ],
            'changes' => [
                'income' => $this->change($current['income'], $before['income']),
                'expense' => $this->change($current['expense'], $before['expense']),
            ],
            'categories' => $categories->map(fn (array $row, string $key) => $row + [
                'previous_total' => $previousCategories->get($key)['total'] ?? 0,
                'change' => $this->change($row['total'], $previousCategories->get($key)['total'] ?? 0),
                'share' => $current['expense'] > 0 ? round($row['total'] * 100 / $current['expense'], 1) : 0.0,
            ])->values()->all(),
            'fixed_vs_variable' => ['fixed' => $fixed, 'variable' => $current['expense'] - $fixed],
            'largest_expenses' => $this->largestExpenses($user, $currency, $period),
            'top_merchants' => $this->topMerchants($user, $currency, $period),
        ];
    }

    /** @return array<int, array<string, mixed>> */
    public function largestExpenses(User $user, string $currency, Period $period, int $limit = 5): array
    {
        return $this->base($user, $currency, $period)
            ->where('transactions.type', 'expense')
            ->leftJoin('categories as c', 'c.id', '=', 'transactions.category_id')
            ->select(['transactions.id', 'transactions.amount', 'transactions.merchant', 'transactions.note', 'transactions.occurred_at', 'c.name as category_name', 'c.default_key'])
            ->orderByDesc('transactions.amount')
            ->limit($limit)
            ->get()
            ->map(fn ($row) => [
                'id' => $row->id,
                'amount' => (int) $row->amount,
                'merchant' => $row->merchant,
                'note' => $row->note,
                'category' => $row->category_name,
                'default_key' => $row->default_key,
                'occurred_at' => CarbonImmutable::parse($row->occurred_at, 'UTC')->toIso8601String(),
            ])->all();
    }

    /** @return array<int, array{merchant: string, count: int, total: int}> */
    public function topMerchants(User $user, string $currency, Period $period, int $limit = 5): array
    {
        return $this->base($user, $currency, $period)
            ->where('transactions.type', 'expense')
            ->whereNotNull('transactions.merchant')
            ->selectRaw('MIN(transactions.merchant) AS merchant, COUNT(*) AS count, SUM(transactions.amount) AS total')
            ->groupByRaw('lower(transactions.merchant)')
            ->orderByDesc('count')
            ->orderByDesc('total')
            ->limit($limit)
            ->get()
            ->map(fn ($row) => ['merchant' => $row->merchant, 'count' => (int) $row->count, 'total' => (int) $row->total])
            ->all();
    }

    /**
     * Income, expense, savings per financial month plus the closing balance
     * of accounts in this currency at the end of each month.
     *
     * @return array<int, array<string, mixed>>
     */
    public function monthlyTrend(User $user, string $currency, int $months, ?CarbonImmutable $now = null): array
    {
        $series = [];
        for ($offset = -($months - 1); $offset <= 0; $offset++) {
            $period = Period::financialMonth($user, $now, $offset);
            $totals = $this->totals($user, $currency, $period);
            $series[] = [
                'period' => $period->toArray($user->timezone),
                'label' => $period->start->setTimezone($user->timezone)->format('Y-m'),
                'income' => $totals['income'],
                'expense' => $totals['expense'],
                'savings' => $totals['income'] - $totals['expense'],
                'savings_rate' => $this->rate($totals['income'] - $totals['expense'], $totals['income']),
                'closing_balance' => $this->balanceAt($user, $currency, min($period->end, $now ?? CarbonImmutable::now())),
            ];
        }

        return $series;
    }

    /** Net balance of included accounts in a currency at a moment in time. */
    public function balanceAt(User $user, string $currency, CarbonImmutable $moment): int
    {
        $accounts = DB::table('accounts')
            ->where('user_id', $user->id)
            ->whereNull('deleted_at')
            ->where('currency', $currency)
            ->where('include_in_total', true);

        $opening = (int) (clone $accounts)->sum('opening_balance');
        $ids = (clone $accounts)->pluck('id');
        if ($ids->isEmpty()) {
            return 0;
        }

        $flows = DB::table('transactions')
            ->whereNull('deleted_at')
            ->where('occurred_at', '<', $moment)
            ->selectRaw("
                COALESCE(SUM(CASE WHEN type = 'income' AND account_id IN ({$this->placeholders($ids)}) THEN amount END), 0)
              - COALESCE(SUM(CASE WHEN type IN ('expense', 'transfer') AND account_id IN ({$this->placeholders($ids)}) THEN amount END), 0)
              + COALESCE(SUM(CASE WHEN type = 'transfer' AND transfer_account_id IN ({$this->placeholders($ids)}) THEN transfer_amount END), 0) AS net
            ", [...$ids, ...$ids, ...$ids])
            ->where(fn ($q) => $q->whereIn('account_id', $ids)->orWhereIn('transfer_account_id', $ids))
            ->value('net');

        return $opening + (int) $flows;
    }

    /** Percent change from $previous to $current, or null when there is no baseline. */
    public function change(int $current, int $previous): ?float
    {
        return $previous === 0 ? null : round(($current - $previous) * 100 / $previous, 1);
    }

    private function rate(int $savings, int $income): ?float
    {
        return $income > 0 ? round($savings * 100 / $income, 1) : null;
    }

    /** @param  Collection<int, mixed>  $values */
    private function placeholders(Collection $values): string
    {
        return implode(',', array_fill(0, $values->count(), '?'));
    }
}
