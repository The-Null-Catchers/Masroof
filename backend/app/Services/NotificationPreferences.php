<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\DB;

class NotificationPreferences
{
    /**
     * Effective channels for a type: stored overrides on top of defaults,
     * gated by the user's master switches for budget and recurring alerts.
     *
     * @return array{in_app: bool, email: bool}
     */
    public function for(User $user, string $type): array
    {
        return $this->all($user)[$type] ?? ['in_app' => false, 'email' => false];
    }

    /** @return array<string, array{in_app: bool, email: bool}> */
    public function all(User $user): array
    {
        $stored = DB::table('notification_preferences')->where('user_id', $user->id)->get()->keyBy('type');
        $settings = $user->settingsOrDefault();
        $result = [];

        foreach (config('masroof.notifications') as $type => $defaults) {
            $row = $stored->get($type);
            $enabled = match ($type) {
                'budget_threshold' => $settings->budget_alerts,
                'bill_reminder', 'recurring_reminder' => $settings->recurring_reminders,
                default => true,
            };
            $result[$type] = [
                'in_app' => $enabled && (bool) ($row->in_app ?? $defaults['in_app']),
                'email' => $enabled && (bool) ($row->email ?? $defaults['email']),
            ];
        }

        return $result;
    }

    /** @param array<string, array{in_app?: bool, email?: bool}> $changes */
    public function update(User $user, array $changes): void
    {
        foreach ($changes as $type => $channels) {
            $defaults = config("masroof.notifications.{$type}");
            $current = DB::table('notification_preferences')->where('user_id', $user->id)->where('type', $type)->first();
            DB::table('notification_preferences')->updateOrInsert(
                ['user_id' => $user->id, 'type' => $type],
                [
                    'in_app' => $channels['in_app'] ?? (bool) ($current->in_app ?? $defaults['in_app']),
                    'email' => $channels['email'] ?? (bool) ($current->email ?? $defaults['email']),
                    'updated_at' => now(),
                    'created_at' => $current->created_at ?? now(),
                ],
            );
        }
    }
}
