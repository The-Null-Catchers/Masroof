<?php

namespace App\Services\Insights\Rules;

use App\Services\AnalyticsService;
use App\Services\Insights\Insight;
use App\Services\Insights\InsightContext;
use App\Services\Insights\InsightRule;
use App\Support\Period;

/**
 * Compares month-to-date category spending with the same number of days of
 * the previous financial month, so partial months are compared fairly.
 */
class CategorySpendingChange implements InsightRule
{
    public const MIN_CHANGE_PERCENT = 15;

    public function __construct(private readonly AnalyticsService $analytics) {}

    public function evaluate(InsightContext $context): array
    {
        $current = new Period($context->month->start, min($context->month->end, $context->now));
        $elapsed = $context->month->start->diffInSeconds($current->end);
        $previousStart = Period::financialMonth($context->user, $context->now, -1)->start;
        $previous = new Period($previousStart, $previousStart->addSeconds((int) $elapsed));

        $now = $this->analytics->expensesByCategory($context->user, $context->currency, $current);
        $before = $this->analytics->expensesByCategory($context->user, $context->currency, $previous);

        $insights = [];
        foreach ($now as $key => $row) {
            $old = $before->get($key)['total'] ?? 0;
            if ($old === 0 || abs($row['total'] - $old) < $context->noticeable()) {
                continue;
            }
            $change = $this->analytics->change($row['total'], $old);
            if ($change === null || abs($change) < self::MIN_CHANGE_PERCENT) {
                continue;
            }
            $insights[] = new Insight(
                key: $change > 0 ? 'category_spending_increased' : 'category_spending_decreased',
                severity: $change > 0 ? 'warning' : 'positive',
                params: ['category' => $this->label($row), 'percent' => (int) round(abs($change))],
                data: ['category_id' => $row['category_id'], 'current' => $row['total'], 'previous' => $old],
                priority: $change > 0 ? 60 : 30,
            );
        }

        return $insights;
    }

    /** @param  array{name: string|null, default_key: string|null}  $row */
    private function label(array $row): string
    {
        $key = "masroof_categories.{$row['default_key']}";

        return $row['default_key'] && trans()->has($key) ? __($key) : ($row['name'] ?? __('insights.uncategorized'));
    }
}
