<?php

namespace App\Jobs;

use App\Models\User;
use App\Services\AlertChecker;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldBeUnique;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

/**
 * Budget checks run after money moves; reminders and summaries run in the
 * user's notification hour. Unique per user so bursts collapse into one run.
 */
class CheckUserAlerts implements ShouldBeUnique, ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $uniqueFor = 60;

    public function __construct(public readonly string $userId, public readonly bool $includeScheduled = false) {}

    public function uniqueId(): string
    {
        return $this->userId.($this->includeScheduled ? ':scheduled' : '');
    }

    public function handle(AlertChecker $checker): void
    {
        $user = User::query()->find($this->userId);
        if ($user === null || $user->isSuspended()) {
            return;
        }

        $checker->budgets($user);
        if ($this->includeScheduled) {
            $checker->goals($user);
            $checker->summaries($user);
        }
    }
}
