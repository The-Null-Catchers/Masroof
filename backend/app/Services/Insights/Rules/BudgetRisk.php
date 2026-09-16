<?php

namespace App\Services\Insights\Rules;

use App\Services\BudgetCalculator;
use App\Services\Insights\Insight;
use App\Services\Insights\InsightContext;
use App\Services\Insights\InsightRule;

/** Warns when a budget passes 70% or is overspent. */
class BudgetRisk implements InsightRule
{
    public const WARNING_PERCENT = 70;

    public function __construct(private readonly BudgetCalculator $calculator) {}

    public function evaluate(InsightContext $context): array
    {
        $insights = [];
        $budgets = $context->user->budgets()->whereNull('archived_at')->with('categories')->get();

        foreach ($budgets as $budget) {
            $progress = $this->calculator->progress($budget, $context->user, $context->now);
            if ($progress['percent'] < self::WARNING_PERCENT || $progress['days_left'] === 0) {
                continue;
            }
            $exceeded = $progress['percent'] >= 100;
            $insights[] = new Insight(
                key: $exceeded ? 'budget_exceeded' : 'budget_at_risk',
                severity: $exceeded ? 'critical' : 'warning',
                params: ['budget' => $budget->name, 'percent' => (int) floor($progress['percent'])],
                data: ['budget_id' => $budget->id, 'percent' => $progress['percent']],
                priority: $exceeded ? 90 : 70,
            );
        }

        return $insights;
    }
}
