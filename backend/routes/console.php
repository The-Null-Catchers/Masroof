<?php

use Illuminate\Support\Facades\Schedule;

Schedule::command('masroof:process-recurring')->hourly()->withoutOverlapping()->onOneServer();
Schedule::command('masroof:send-notifications')->hourlyAt(5)->withoutOverlapping()->onOneServer();
Schedule::command('masroof:verify-balances')->dailyAt('03:00')->withoutOverlapping()->onOneServer();
Schedule::command('sanctum:prune-expired --hours=24')->daily();
Schedule::command('auth:clear-resets')->everyFifteenMinutes();
Schedule::command('queue:prune-failed --hours=168')->daily();
Schedule::command('masroof:prune-exports')->daily();
Schedule::command('masroof:prune-receipts')->daily();
