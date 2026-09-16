<?php

namespace App\Services;

use App\Models\Budget;
use App\Models\Category;
use App\Models\User;
use App\Support\Period;
use Carbon\CarbonImmutable;

/**
 * Deterministic budget progress. Only expenses in the budget's currency count;
 * category scopes include their subcategories. Transfers never count.
 */
class BudgetCalculator
{
    public function periodFor(Budget $budget, User $user, ?CarbonImmutable $now = null): Period
    {
        return match ($budget->period) {
            'weekly' => Period::week($user, $now),
            'custom' => Period::dates($user, (string) $budget->starts_on?->toDateString(), (string) $budget->ends_on?->toDateString()),
            default => Period::financialMonth($user, $now),
        };
    }

    /**
     * @return array{
     *     period: array{start: string, end: string}, spent: int, remaining: int, percent: float,
     *     days_left: int, safe_to_spend_daily: int, expected_spent: int, projected_spent: int,
     *     reached_thresholds: array<int, int>, status: string
     * }
     */
    public function progress(Budget $budget, User $user, ?CarbonImmutable $now = null): array
    {
        $now ??= CarbonImmutable::now();
        $period = $this->periodFor($budget, $user, $now);
        $spent = $this->spent($budget, $user, $period);
        $fixedSpent = $this->spent($budget, $user, $period, fixedOnly: true);

        $remaining = $budget->amount - $spent;
        $percent = round($spent * 100 / $budget->amount, 1);
        $daysLeft = $period->daysLeft($user->timezone, $now);
        $totalDays = max(1, $period->days($user->timezone));
        $elapsedDays = max(1, min($totalDays, $totalDays - $daysLeft + 1));

        $reached = array_values(array_filter(
            $this->thresholds($budget),
            fn (int $threshold) => $percent >= $threshold,
        ));

        return [
            'period' => $period->toArray($user->timezone),
            'spent' => $spent,
            'remaining' => $remaining,
            'percent' => $percent,
            'days_left' => $daysLeft,
            // What can still be spent per remaining day without exceeding the budget.
            'safe_to_spend_daily' => $daysLeft > 0 ? intdiv(max($remaining, 0), $daysLeft) : 0,
            // Linear pace: how much "should" be spent by today.
            'expected_spent' => intdiv($budget->amount * $elapsedDays, $totalDays),
            // Fixed costs (rent, bills…) are paid once, so only variable spending is extrapolated.
            'projected_spent' => $now->lt($period->start) ? 0 : $fixedSpent + intdiv(($spent - $fixedSpent) * $totalDays, $elapsedDays),
            'reached_thresholds' => $reached,
            'status' => match (true) {
                $percent >= 100 => 'exceeded',
                $reached !== [] => 'warning',
                default => 'on_track',
            },
        ];
    }

    public function spent(Budget $budget, User $user, Period $period, bool $fixedOnly = false): int
    {
        $categoryIds = $this->scopeCategoryIds($budget);

        return (int) $user->transactions()
            ->when($fixedOnly, fn ($q) => $q->whereHas('category', fn ($c) => $c->where('is_fixed', true)))
            ->where('type', 'expense')
            ->where('currency', $budget->currency)
            ->where('occurred_at', '>=', $period->start)
            ->where('occurred_at', '<', $period->end)
            ->when($categoryIds !== null, fn ($q) => $q->whereIn('category_id', $categoryIds))
            ->sum('amount');
    }

    /** @return array<int, int> */
    public function thresholds(Budget $budget): array
    {
        $values = array_map('intval', $budget->alert_thresholds ?: Budget::DEFAULT_THRESHOLDS);
        sort($values);

        return array_values(array_unique($values));
    }

    /**
     * Selected categories plus their subcategories, or null for all categories.
     *
     * @return array<int, string>|null
     */
    private function scopeCategoryIds(Budget $budget): ?array
    {
        $selected = $budget->relationLoaded('categories')
            ? $budget->categories->pluck('id')->all()
            : $budget->categories()->pluck('categories.id')->all();

        if ($selected === []) {
            return null;
        }

        $children = Category::query()->whereIn('parent_id', $selected)->pluck('id')->all();

        return array_values(array_unique([...$selected, ...$children]));
    }
}
