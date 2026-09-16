<?php

namespace App\Services;

use App\Models\Goal;
use App\Models\GoalTransaction;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class GoalService
{
    public function addEntry(Goal $goal, string $type, int $amount, CarbonImmutable $occurredAt, ?string $note = null): GoalTransaction
    {
        return DB::transaction(function () use ($goal, $type, $amount, $occurredAt, $note) {
            $locked = Goal::query()->lockForUpdate()->findOrFail($goal->id);

            if ($type === 'withdrawal' && $amount > $locked->current_amount) {
                throw ValidationException::withMessages(['amount' => __('masroof.goal_withdrawal_exceeds')]);
            }

            $entry = $locked->entries()->create(['type' => $type, 'amount' => $amount, 'occurred_at' => $occurredAt, 'note' => $note]);
            $this->apply($locked, $entry->signedAmount());

            return $entry;
        });
    }

    public function deleteEntry(GoalTransaction $entry): void
    {
        DB::transaction(function () use ($entry) {
            $goal = Goal::query()->lockForUpdate()->findOrFail($entry->goal_id);

            if ($goal->current_amount - $entry->signedAmount() < 0) {
                throw ValidationException::withMessages(['entry' => __('masroof.goal_entry_in_use')]);
            }

            $entry->delete();
            $this->apply($goal, -$entry->signedAmount());
        });
    }

    /**
     * @return array{percent: float, remaining: int, monthly_needed: int|null, expected_completion_date: string|null, average_monthly_contribution: int}
     */
    public function stats(Goal $goal, ?CarbonImmutable $now = null): array
    {
        $now ??= CarbonImmutable::now();
        $remaining = max(0, $goal->target_amount - $goal->current_amount);

        $monthlyNeeded = null;
        if ($goal->target_date !== null && $remaining > 0) {
            // Whole months left, rounded to the nearest month (min 1).
            $months = max(1, (int) round($now->diffInMonths(CarbonImmutable::parse($goal->target_date->toDateString())->endOfDay(), false)));
            $monthlyNeeded = (int) ceil($remaining / $months);
        }

        $average = $this->averageMonthlyContribution($goal, $now);
        $expected = match (true) {
            $remaining === 0 => ($goal->achieved_at ?? $now)->toDateString(),
            $average > 0 => $now->addDays((int) ceil($remaining / $average * 30.4375))->toDateString(),
            default => null,
        };

        return [
            'percent' => round(min(100, $goal->current_amount * 100 / $goal->target_amount), 1),
            'remaining' => $remaining,
            'monthly_needed' => $monthlyNeeded,
            'expected_completion_date' => $expected,
            'average_monthly_contribution' => $average,
        ];
    }

    /** Net monthly saving pace over the last 90 days (or since the first entry). */
    private function averageMonthlyContribution(Goal $goal, CarbonImmutable $now): int
    {
        $since = $now->subDays(90);
        $entries = $goal->entries()->where('occurred_at', '>=', $since)->get();
        if ($entries->isEmpty()) {
            return 0;
        }

        $net = $entries->sum(fn (GoalTransaction $e) => $e->signedAmount());
        $first = CarbonImmutable::parse($entries->min('occurred_at'));
        $days = max(30.4375, $first->diffInDays($now));

        return (int) floor($net / ($days / 30.4375));
    }

    private function apply(Goal $goal, int $delta): void
    {
        $goal->current_amount += $delta;
        $reached = $goal->current_amount >= $goal->target_amount;
        $goal->achieved_at = $reached ? ($goal->achieved_at ?? now()) : null;
        $goal->save();
    }
}
