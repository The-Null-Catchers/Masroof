<?php

namespace App\Services;

use App\Models\User;
use App\Notifications\MasroofNotification;
use Illuminate\Support\Facades\DB;

class NotificationService
{
    public function __construct(private readonly NotificationPreferences $preferences) {}

    /**
     * Sends a notification at most once per dedupe key. The ledger row is
     * written first, so concurrent workers cannot both deliver it.
     */
    public function sendOnce(User $user, MasroofNotification $notification, string $dedupeKey): bool
    {
        $channels = $this->preferences->for($user, $notification->type());
        if (! $channels['in_app'] && ! $channels['email']) {
            return false;
        }

        $inserted = DB::table('notification_deliveries')->insertOrIgnore([
            'user_id' => $user->id,
            'dedupe_key' => $dedupeKey,
            'created_at' => now(),
        ]);
        if ($inserted === 0) {
            return false;
        }

        $user->notify($notification);

        return true;
    }

    /** Marks a key as handled without notifying (e.g. lower thresholds skipped over). */
    public function markDelivered(User $user, string $dedupeKey): void
    {
        DB::table('notification_deliveries')->insertOrIgnore(['user_id' => $user->id, 'dedupe_key' => $dedupeKey, 'created_at' => now()]);
    }
}
