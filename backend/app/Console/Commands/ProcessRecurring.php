<?php

namespace App\Console\Commands;

use App\Jobs\ProcessRecurringTransaction;
use App\Models\RecurringTransaction;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

#[Signature('masroof:process-recurring')]
#[Description('Queue recurring transactions that are due or need a reminder')]
class ProcessRecurring extends Command
{
    public function handle(): int
    {
        // A week of look-ahead covers reminders; timezones are resolved per rule.
        $count = 0;
        RecurringTransaction::query()
            ->whereNull('paused_at')
            ->whereNotNull('next_occurrence_on')
            ->where('next_occurrence_on', '<=', now()->addDays(8)->toDateString())
            ->select('id')
            ->lazyById(500)
            ->each(function (RecurringTransaction $rule) use (&$count) {
                ProcessRecurringTransaction::dispatch($rule->id);
                $count++;
            });

        $this->info("Queued {$count} recurring rule(s).");

        return self::SUCCESS;
    }
}
