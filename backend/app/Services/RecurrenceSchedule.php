<?php

namespace App\Services;

use App\Models\RecurringTransaction;
use Carbon\CarbonImmutable;

/**
 * Pure date arithmetic for recurring rules. Occurrence n is always computed
 * from the start date (not from the previous occurrence), so a rule that
 * starts on the 31st lands on Feb 28 and returns to Mar 31.
 */
class RecurrenceSchedule
{
    public function occurrence(RecurringTransaction $rule, int $n): CarbonImmutable
    {
        $start = CarbonImmutable::parse($rule->starts_on->toDateString());
        $steps = $n * max(1, $rule->interval);

        return match ($rule->frequency) {
            'daily' => $start->addDays($steps),
            'weekly' => $start->addWeeks($steps),
            'yearly' => $start->addYearsNoOverflow($steps),
            default => $start->addMonthsNoOverflow($steps),
        };
    }

    /** First occurrence on or after $date, or null when the rule has ended. */
    public function nextOnOrAfter(RecurringTransaction $rule, CarbonImmutable $date): ?CarbonImmutable
    {
        $start = CarbonImmutable::parse($rule->starts_on->toDateString());
        if ($date->lte($start)) {
            return $this->withinEnd($rule, $start);
        }

        // Jump close to the target, then step forward (handles month-length drift).
        $unitsBetween = match ($rule->frequency) {
            'daily' => (int) $start->diffInDays($date),
            'weekly' => (int) floor($start->diffInDays($date) / 7),
            'yearly' => (int) $start->diffInYears($date),
            default => (int) $start->diffInMonths($date),
        };
        $n = max(0, intdiv($unitsBetween, max(1, $rule->interval)) - 1);

        while (($candidate = $this->occurrence($rule, $n))->lt($date)) {
            $n++;
        }

        return $this->withinEnd($rule, $candidate);
    }

    /**
     * Occurrences from the rule's next date through $today (inclusive).
     *
     * @return array<int, CarbonImmutable>
     */
    public function dueThrough(RecurringTransaction $rule, CarbonImmutable $today, int $limit = 60): array
    {
        $dates = [];
        $next = $rule->next_occurrence_on ? CarbonImmutable::parse($rule->next_occurrence_on->toDateString()) : null;

        while ($next !== null && $next->lte($today) && count($dates) < $limit) {
            $dates[] = $next;
            $next = $this->nextOnOrAfter($rule, $next->addDay());
        }

        return $dates;
    }

    private function withinEnd(RecurringTransaction $rule, CarbonImmutable $date): ?CarbonImmutable
    {
        if ($rule->ends_on !== null && $date->gt(CarbonImmutable::parse($rule->ends_on->toDateString()))) {
            return null;
        }

        return $date;
    }
}
