<?php

namespace App\Notifications;

use App\Models\User;
use App\Services\NotificationPreferences;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

/**
 * Base for product notifications. Stored data holds translation keys and
 * parameters (not rendered text) so the inbox follows the reader's language.
 */
abstract class MasroofNotification extends Notification implements ShouldQueue
{
    use Queueable;

    /** Preference type, e.g. "budget_threshold". */
    abstract public function type(): string;

    /** @return array<string, string|int|float> */
    abstract public function params(): array;

    /** Deep link path inside the apps, e.g. "/budgets". */
    abstract public function action(): ?string;

    /** @return array<int, string> */
    public function via(User $notifiable): array
    {
        $preference = app(NotificationPreferences::class)->for($notifiable, $this->type());

        return array_values(array_filter([
            $preference['in_app'] ? 'database' : null,
            $preference['email'] ? 'mail' : null,
        ]));
    }

    /** @return array<string, mixed> */
    public function toArray(User $notifiable): array
    {
        return ['type' => $this->type(), 'params' => $this->params(), 'action' => $this->action()];
    }

    public function toMail(User $notifiable): MailMessage
    {
        $params = $this->params();
        $message = (new MailMessage)
            ->subject(__("notifications.{$this->type()}.title", $params))
            ->greeting(__('notifications.greeting', ['name' => $notifiable->name]))
            ->line(__("notifications.{$this->type()}.body", $params));

        if ($this->action() !== null) {
            $message->action(__('notifications.open_app'), rtrim((string) config('masroof.frontend_url'), '/').$this->action());
        }

        return $message;
    }
}
