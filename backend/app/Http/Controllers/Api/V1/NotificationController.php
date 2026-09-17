<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Notifications\MasroofNotification;
use App\Services\NotificationPreferences;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Notifications\DatabaseNotification;

class NotificationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $request->validate(['unread' => ['sometimes', 'boolean'], 'per_page' => ['sometimes', 'integer', 'between:1,100']]);
        $user = $request->user();

        $page = $user->notifications()
            ->when($request->boolean('unread'), fn ($q) => $q->whereNull('read_at'))
            ->paginate((int) $request->input('per_page', 20));

        return response()->json([
            'data' => collect($page->items())->map(fn (DatabaseNotification $n) => $this->present($n))->values(),
            'meta' => [
                'current_page' => $page->currentPage(),
                'last_page' => $page->lastPage(),
                'total' => $page->total(),
                'unread_count' => $user->unreadNotifications()->count(),
            ],
        ]);
    }

    public function markRead(Request $request, string $id): JsonResponse
    {
        $notification = $request->user()->notifications()->findOrFail($id);
        $notification->markAsRead();

        return response()->json(['data' => $this->present($notification)]);
    }

    public function markAllRead(Request $request): JsonResponse
    {
        $request->user()->unreadNotifications()->update(['read_at' => now()]);

        return response()->json(null, 204);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $request->user()->notifications()->findOrFail($id)->delete();

        return response()->json(null, 204);
    }

    public function preferences(Request $request, NotificationPreferences $preferences): JsonResponse
    {
        return response()->json(['data' => $preferences->all($request->user())]);
    }

    public function updatePreferences(Request $request, NotificationPreferences $preferences): JsonResponse
    {
        $types = array_keys(config('masroof.notifications'));
        $data = $request->validate([
            'preferences' => ['required', 'array'],
            'preferences.*' => ['array'],
            'preferences.*.in_app' => ['sometimes', 'boolean'],
            'preferences.*.email' => ['sometimes', 'boolean'],
        ]);
        foreach (array_keys($data['preferences']) as $type) {
            if (! in_array($type, $types, true)) {
                abort(422, __('validation.in', ['attribute' => $type]));
            }
        }

        $preferences->update($request->user(), $data['preferences']);

        return response()->json(['data' => $preferences->all($request->user())]);
    }

    /**
     * Renders stored keys in the reader's current language.
     *
     * @return array<string, mixed>
     */
    private function present(DatabaseNotification $notification): array
    {
        $data = $notification->data;
        $type = $data['type'] ?? 'unknown';
        $params = MasroofNotification::localizeParams($data['params'] ?? []);

        return [
            'id' => $notification->id,
            'type' => $type,
            'title' => __("notifications.{$type}.title", $params),
            'body' => __("notifications.{$type}.body", $params),
            'action' => $data['action'] ?? null,
            'read' => $notification->read_at !== null,
            'created_at' => $notification->created_at?->toIso8601String(),
        ];
    }
}
