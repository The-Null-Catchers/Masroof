<?php

namespace App\Services;

use App\Models\Category;
use App\Models\RecurringTransaction;
use App\Notifications\RecurringPaymentDue;
use Carbon\CarbonImmutable;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Facades\DB;

class RecurringService
{
    public function __construct(
        private readonly RecurrenceSchedule $schedule,
        private readonly TransactionService $transactions,
        private readonly NotificationService $notifications,
    ) {}

    /**
     * Today's calendar date in the owner's timezone, as a date value in the
     * app timezone so it compares correctly with stored DATE columns.
     */
    public function today(RecurringTransaction $rule, ?CarbonImmutable $now = null): CarbonImmutable
    {
        return CarbonImmutable::parse(($now ?? CarbonImmutable::now())->setTimezone($rule->user->timezone)->toDateString());
    }

    /**
     * (Re)computes the next pending occurrence. New rules start from their
     * start date; edited rules never re-generate dates that already passed.
     */
    public function reschedule(RecurringTransaction $rule, ?CarbonImmutable $now = null): void
    {
        $from = CarbonImmutable::parse($rule->starts_on->toDateString());
        if ($rule->exists && $rule->next_occurrence_on !== null) {
            $from = $from->max(CarbonImmutable::parse($rule->next_occurrence_on->toDateString()));
        }
        $rule->next_occurrence_on = $this->schedule->nextOnOrAfter($rule, $from);
    }

    /**
     * Generates due transactions (auto mode) or sends reminders (remind mode).
     * Safe to run repeatedly and concurrently: the rule row is locked and a
     * unique index makes each (rule, date) transaction impossible to duplicate.
     *
     * @return int Number of transactions created.
     */
    public function process(RecurringTransaction $rule, ?CarbonImmutable $now = null): int
    {
        return DB::transaction(function () use ($rule, $now) {
            $rule = RecurringTransaction::query()->with('user')->lockForUpdate()->find($rule->id);
            if ($rule === null || $rule->paused_at !== null || $rule->next_occurrence_on === null) {
                return 0;
            }

            $today = $this->today($rule, $now);
            $this->remindIfUpcoming($rule, $today);

            $created = 0;
            foreach ($this->schedule->dueThrough($rule, $today) as $date) {
                if ($rule->mode === 'auto' && $this->createOccurrence($rule, $date)) {
                    $created++;
                }
                $rule->next_occurrence_on = $this->schedule->nextOnOrAfter($rule, $date->addDay());
            }
            $rule->save();

            return $created;
        });
    }

    private function createOccurrence(RecurringTransaction $rule, CarbonImmutable $date): bool
    {
        // Keep the account's currency rules: skip if the account was archived or removed.
        $account = $rule->account;
        if ($account === null || $account->trashed() || $account->archived_at !== null) {
            return false;
        }

        try {
            DB::transaction(fn () => $this->transactions->create($rule->user, [
                'type' => $rule->type,
                'account_id' => $rule->account_id,
                'category_id' => $rule->category_id,
                'transfer_account_id' => $rule->transfer_account_id,
                'amount' => $rule->amount,
                'transfer_amount' => $rule->transfer_amount,
                'merchant' => $rule->merchant,
                'payment_method' => $rule->payment_method,
                'note' => $rule->note,
                // Midday local time keeps the date stable across timezones.
                'occurred_at' => CarbonImmutable::parse($date->toDateString().' 12:00', $rule->user->timezone)->utc(),
                'recurring_transaction_id' => $rule->id,
                'recurring_occurrence_on' => $date->toDateString(),
            ]));

            return true;
        } catch (UniqueConstraintViolationException) {
            return false;
        }
    }

    private function remindIfUpcoming(RecurringTransaction $rule, CarbonImmutable $today): void
    {
        if ($rule->mode !== 'remind' || $rule->next_occurrence_on === null) {
            return;
        }
        $due = CarbonImmutable::parse($rule->next_occurrence_on->toDateString());
        if ($today->lt($due->subDays($rule->remind_days_before)) || $today->gt($due)) {
            return;
        }

        $isBill = $rule->category_id !== null
            && in_array(Category::query()->whereKey($rule->category_id)->value('default_key'), DefaultCategories::FIXED, true);

        $this->notifications->sendOnce($rule->user, new RecurringPaymentDue(
            $rule->id,
            $rule->name,
            $rule->amount,
            $rule->currency,
            $due->toDateString(),
            $isBill,
        ), "recurring:{$rule->id}:{$due->toDateString()}");
    }
}
