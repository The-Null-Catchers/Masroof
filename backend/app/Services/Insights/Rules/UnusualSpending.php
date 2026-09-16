<?php

namespace App\Services\Insights\Rules;

use App\Services\AnalyticsService;
use App\Services\Insights\Insight;
use App\Services\Insights\InsightContext;
use App\Services\Insights\InsightRule;
use App\Support\Period;

/**
 * Projects this month's spending at the current pace and compares it with the
 * average of the previous three months that had spending.
 */
class UnusualSpending implements InsightRule
{
    public const THRESHOLD = 1.3;

    /** Too early in the month for a meaningful projection. */
    public const MIN_ELAPSED_DAYS = 7;

    public function __construct(private readonly AnalyticsService $analytics) {}

    public function evaluate(InsightContext $context): array
    {
        $tz = $context->user->timezone;
        $totalDays = $context->month->days($tz);
        $elapsed = $totalDays - $context->month->daysLeft($tz, $context->now) + 1;
        if ($elapsed < self::MIN_ELAPSED_DAYS) {
            return [];
        }

        $history = collect([-1, -2, -3])
            ->map(fn (int $offset) => $this->analytics->totals($context->user, $context->currency, Period::financialMonth($context->user, $context->now, $offset))['expense'])
            ->filter(fn (int $expense) => $expense > 0);
        if ($history->count() < 2) {
            return [];
        }

        $spent = $this->analytics->totals($context->user, $context->currency, $context->month)['expense'];
        $projected = intdiv($spent * $totalDays, $elapsed);
        $average = (int) round($history->avg());

        if ($projected < $average * self::THRESHOLD || $projected - $average < $context->noticeable(50)) {
            return [];
        }

        return [new Insight(
            key: 'unusual_spending',
            severity: 'warning',
            params: ['percent' => (int) round(($projected - $average) * 100 / $average), 'projected' => $context->money($projected)],
            data: ['projected' => $projected, 'average' => $average],
            priority: 75,
        )];
    }
}
