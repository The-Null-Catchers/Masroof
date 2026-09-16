<?php

namespace App\Services\Insights\Rules;

use App\Models\Transaction;
use App\Services\Insights\Insight;
use App\Services\Insights\InsightContext;
use App\Services\Insights\InsightRule;
use App\Support\Money;

/**
 * Same account, type, amount and merchant (or category when there is no
 * merchant) within 48 hours in the last two weeks.
 */
class DuplicateTransactions implements InsightRule
{
    public const WINDOW_HOURS = 48;

    public function evaluate(InsightContext $context): array
    {
        $recent = $context->user->transactions()
            ->whereIn('type', ['expense', 'income'])
            ->where('occurred_at', '>=', $context->now->subDays(14))
            ->orderBy('occurred_at')
            ->get();

        $insights = [];
        $seen = [];
        foreach ($recent->groupBy(fn (Transaction $t) => implode('|', [$t->account_id, $t->type->value, $t->amount, mb_strtolower((string) ($t->merchant ?? $t->category_id))])) as $group) {
            for ($i = 1; $i < $group->count(); $i++) {
                $a = $group[$i - 1];
                $b = $group[$i];
                if ($a->occurred_at->diffInHours($b->occurred_at) > self::WINDOW_HOURS || isset($seen[$a->id])) {
                    continue;
                }
                $seen[$a->id] = $seen[$b->id] = true;
                $insights[] = new Insight(
                    key: 'possible_duplicate',
                    severity: 'warning',
                    params: ['amount' => Money::display($a->amount, $a->currency), 'merchant' => $a->merchant ?? '—'],
                    data: ['transaction_ids' => [$a->id, $b->id]],
                    priority: 80,
                );
            }
        }

        return $insights;
    }
}
