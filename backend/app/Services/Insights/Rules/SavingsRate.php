<?php

namespace App\Services\Insights\Rules;

use App\Services\AnalyticsService;
use App\Services\Insights\Insight;
use App\Services\Insights\InsightContext;
use App\Services\Insights\InsightRule;

/** Reports the month's savings rate once there is income to measure it. */
class SavingsRate implements InsightRule
{
    public const LOW_PERCENT = 10;

    public const HEALTHY_PERCENT = 20;

    public function __construct(private readonly AnalyticsService $analytics) {}

    public function evaluate(InsightContext $context): array
    {
        $totals = $this->analytics->totals($context->user, $context->currency, $context->month);
        if ($totals['income'] <= 0) {
            return [];
        }

        $rate = (int) round(($totals['income'] - $totals['expense']) * 100 / $totals['income']);

        return [new Insight(
            key: $rate < self::LOW_PERCENT ? 'savings_rate_low' : 'savings_rate',
            severity: match (true) {
                $rate < 0 => 'critical',
                $rate < self::LOW_PERCENT => 'warning',
                $rate >= self::HEALTHY_PERCENT => 'positive',
                default => 'info',
            },
            params: ['percent' => $rate],
            data: ['rate' => $rate, 'income' => $totals['income'], 'expense' => $totals['expense']],
            priority: $rate < self::LOW_PERCENT ? 65 : 20,
        )];
    }
}
