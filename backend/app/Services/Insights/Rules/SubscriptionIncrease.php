<?php

namespace App\Services\Insights\Rules;

use App\Models\Transaction;
use App\Services\Insights\Insight;
use App\Services\Insights\InsightContext;
use App\Services\Insights\InsightRule;
use App\Support\Money;
use Illuminate\Support\Collection;

/**
 * A merchant charged about once a month for at least three of the last four
 * months with stable amounts (a likely subscription or bill) whose latest
 * charge is at least 5% higher than before.
 */
class SubscriptionIncrease implements InsightRule
{
    public const MIN_INCREASE_PERCENT = 5;

    public function evaluate(InsightContext $context): array
    {
        $charges = $context->user->transactions()
            ->where('type', 'expense')
            ->where('currency', $context->currency)
            ->whereNotNull('merchant')
            ->where('occurred_at', '>=', $context->now->subMonths(4))
            ->orderBy('occurred_at')
            ->get(['id', 'merchant', 'amount', 'occurred_at']);

        $insights = [];
        foreach ($charges->groupBy(fn ($t) => mb_strtolower($t->merchant)) as $group) {
            /** @var Collection<int, Transaction> $group */
            $months = $group->map(fn ($t) => $t->occurred_at->format('Y-m'))->unique();
            // Subscription-like: about one charge per month, in at least three months.
            if ($months->count() < 3 || $group->count() > $months->count()) {
                continue;
            }
            $latest = $group->last();
            $earlier = $group->slice(0, -1)->pluck('amount');
            $previous = $group->slice(0, -1)->last();
            // Earlier charges must be stable (within 10%) for an increase to be meaningful.
            if ($previous === null || $previous->amount <= 0 || $earlier->max() > $earlier->min() * 1.1) {
                continue;
            }
            $increase = ($latest->amount - $previous->amount) * 100 / $previous->amount;
            if ($increase < self::MIN_INCREASE_PERCENT) {
                continue;
            }
            $insights[] = new Insight(
                key: 'subscription_increase',
                severity: 'warning',
                params: [
                    'merchant' => $latest->merchant,
                    'percent' => (int) round($increase),
                    'amount' => Money::toDecimal($latest->amount, $context->currency).' '.$context->currency,
                ],
                data: ['transaction_id' => $latest->id, 'previous_amount' => $previous->amount],
                priority: 70,
            );
        }

        return $insights;
    }
}
