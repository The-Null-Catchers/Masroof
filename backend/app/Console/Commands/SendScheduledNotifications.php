<?php

namespace App\Console\Commands;

use App\Jobs\CheckUserAlerts;
use App\Models\User;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

#[Signature('masroof:send-notifications {--all : Ignore the local notification hour (useful for testing)}')]
#[Description('Queue budget alerts for everyone and reminders/summaries for users in their notification hour')]
class SendScheduledNotifications extends Command
{
    public function handle(): int
    {
        $hour = (int) config('masroof.notification_hour');

        User::query()->whereNull('suspended_at')->select(['id', 'timezone'])->lazyById(500)->each(function (User $user) use ($hour) {
            $inWindow = $this->option('all') || now($user->timezone)->hour === $hour;
            CheckUserAlerts::dispatch($user->id, $inWindow);
        });

        return self::SUCCESS;
    }
}
