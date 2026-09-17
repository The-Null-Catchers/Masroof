<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Validation\Rule;

/**
 * Account administration. Exposes identity and account-state fields only;
 * financial records are never readable through the admin API.
 */
class UserController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $request->validate([
            'search' => ['sometimes', 'nullable', 'string', 'max:100'],
            'status' => ['sometimes', 'nullable', Rule::in(['active', 'suspended', 'unverified'])],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'],
        ]);

        $users = User::query()
            ->when($request->filled('search'), function (Builder $q) use ($request) {
                $term = '%'.str_replace(['\\', '%', '_'], ['\\\\', '\\%', '\\_'], mb_strtolower((string) $request->input('search'))).'%';
                $q->where(fn (Builder $w) => $w->whereRaw('lower(email) LIKE ?', [$term])->orWhereRaw('lower(name) LIKE ?', [$term]));
            })
            ->when($request->input('status') === 'suspended', fn (Builder $q) => $q->whereNotNull('suspended_at'))
            ->when($request->input('status') === 'active', fn (Builder $q) => $q->whereNull('suspended_at'))
            ->when($request->input('status') === 'unverified', fn (Builder $q) => $q->whereNull('email_verified_at'))
            ->withMax('tokens as last_active_at', 'last_used_at')
            ->latest()
            ->paginate((int) $request->input('per_page', 25));

        return response()->json([
            'data' => $users->getCollection()->map(fn (User $user) => $this->present($user))->values(),
            'meta' => [
                'current_page' => $users->currentPage(),
                'last_page' => $users->lastPage(),
                'per_page' => $users->perPage(),
                'total' => $users->total(),
            ],
        ]);
    }

    public function suspend(Request $request, User $user): JsonResponse
    {
        $data = $request->validate(['reason' => ['sometimes', 'nullable', 'string', 'max:255']]);
        abort_if($user->is($request->user()), 422, __('masroof.admin_cannot_suspend_self'));
        abort_if($user->role === UserRole::Admin, 422, __('masroof.admin_cannot_suspend_admin'));

        if ($user->suspended_at === null) {
            $user->forceFill(['suspended_at' => now()])->save();
            // Suspension signs the user out everywhere.
            $user->tokens()->delete();
            AdminAuditLog::record($request->user(), 'user.suspended', $user, ['reason' => $data['reason'] ?? null]);
        }

        return response()->json(['data' => $this->present($user->loadMax('tokens as last_active_at', 'last_used_at'))]);
    }

    public function reactivate(Request $request, User $user): JsonResponse
    {
        if ($user->suspended_at !== null) {
            $user->forceFill(['suspended_at' => null])->save();
            AdminAuditLog::record($request->user(), 'user.reactivated', $user);
        }

        return response()->json(['data' => $this->present($user->loadMax('tokens as last_active_at', 'last_used_at'))]);
    }

    public function audit(): JsonResponse
    {
        $logs = AdminAuditLog::query()->with(['admin:id,name,email', 'target:id,name,email'])->latest('id')->limit(100)->get();

        return response()->json(['data' => $logs->map(fn (AdminAuditLog $log) => [
            'id' => $log->id,
            'action' => $log->action,
            'admin' => $log->admin?->only(['id', 'name', 'email']),
            'target' => $log->target?->only(['id', 'name', 'email']),
            'meta' => $log->meta,
            'created_at' => $log->created_at->toIso8601String(),
        ])]);
    }

    /** @return array<string, mixed> */
    private function present(User $user): array
    {
        $lastActive = $user->getAttribute('last_active_at');

        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'role' => $user->role->value,
            'locale' => $user->locale,
            'currency' => $user->currency,
            'email_verified' => $user->email_verified_at !== null,
            'suspended' => $user->suspended_at !== null,
            'suspended_at' => $user->suspended_at?->toIso8601String(),
            'last_active_at' => $lastActive ? Carbon::parse($lastActive)->toIso8601String() : null,
            'created_at' => $user->created_at?->toIso8601String(),
        ];
    }
}
