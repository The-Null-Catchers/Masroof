<?php

namespace App\Services\Insights;

use App\Models\User;
use App\Services\Insights\Rules\BudgetRisk;
use App\Services\Insights\Rules\CategorySpendingChange;
use App\Services\Insights\Rules\DuplicateTransactions;
use App\Services\Insights\Rules\LargePurchase;
use App\Services\Insights\Rules\SavingsRate;
use App\Services\Insights\Rules\SubscriptionIncrease;
use App\Services\Insights\Rules\UnusualSpending;
use Carbon\CarbonImmutable;

/**
 * Runs every rule and returns insights ordered by importance. Rules are plain
 * deterministic calculations — no AI — so results are reproducible and testable.
 */
class InsightEngine
{
    /** @var array<int, class-string<InsightRule>> */
    public const RULES = [
        BudgetRisk::class,
        DuplicateTransactions::class,
        UnusualSpending::class,
        SubscriptionIncrease::class,
        SavingsRate::class,
        CategorySpendingChange::class,
        LargePurchase::class,
    ];

    /** @return array<int, Insight> */
    public function generate(User $user, ?string $currency = null, ?CarbonImmutable $now = null): array
    {
        $context = new InsightContext($user, $currency ?? $user->currency, $now ?? CarbonImmutable::now());

        $insights = [];
        foreach (self::RULES as $rule) {
            array_push($insights, ...app($rule)->evaluate($context));
        }

        usort($insights, fn (Insight $a, Insight $b) => $b->priority <=> $a->priority);

        return $insights;
    }
}
