<?php

namespace App\Services\Insights\Rules;

use App\Services\Insights\Insight;
use App\Services\Insights\InsightContext;
use App\Services\Insights\InsightRule;
use App\Support\Money;

/** Flags recent expenses far above the user's typical (median) expense. */
class LargePurchase implements InsightRule
{
    public const MULTIPLIER = 4;

    public const MIN_HISTORY = 10;

    public function evaluate(InsightContext $context): array
    {
        $amounts = $context->user->transactions()
            ->where('type', 'expense')
            ->where('currency', $context->currency)
            ->where('occurred_at', '>=', $context->now->subDays(90))
            ->where('occurred_at', '<', $context->now->subDays(7))
            ->orderBy('amount')
            ->pluck('amount');
        if ($amounts->count() < self::MIN_HISTORY) {
            return [];
        }

        $median = (int) $amounts[intdiv($amounts->count(), 2)];
        $threshold = max($median * self::MULTIPLIER, $context->noticeable(100));

        return $context->user->transactions()
            ->where('type', 'expense')
            ->where('currency', $context->currency)
            ->where('occurred_at', '>=', $context->now->subDays(7))
            ->where('amount', '>=', $threshold)
            ->orderByDesc('amount')
            ->limit(3)
            ->get()
            ->map(fn ($tx) => new Insight(
                key: 'large_purchase',
                severity: 'info',
                params: ['amount' => Money::display($tx->amount, $tx->currency), 'merchant' => $tx->merchant ?? '—'],
                data: ['transaction_id' => $tx->id, 'median' => $median],
                priority: 55,
            ))
            ->all();
    }
}
