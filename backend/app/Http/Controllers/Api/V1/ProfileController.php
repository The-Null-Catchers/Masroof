<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\ChangePasswordRequest;
use App\Http\Requests\Api\V1\UpdateProfileRequest;
use App\Http\Resources\V1\UserResource;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Laravel\Sanctum\PersonalAccessToken;
use Laravel\Sanctum\TransientToken;

class ProfileController extends Controller
{
    public function show(Request $request): UserResource
    {
        return new UserResource($request->user());
    }

    public function update(UpdateProfileRequest $request): UserResource
    {
        $user = $request->user();
        $user->fill($request->validated())->save();

        return new UserResource($user);
    }

    public function changePassword(ChangePasswordRequest $request): JsonResponse
    {
        $user = $request->user();
        $user->forceFill(['password' => $request->input('password')])->save();

        // Keep the current device signed in; revoke all others.
        /** @var PersonalAccessToken|TransientToken $current */
        $current = $user->currentAccessToken();
        $user->tokens()->when($current instanceof PersonalAccessToken, fn ($q) => $q->whereKeyNot($current->getKey()))->delete();

        return response()->json(['message' => __('masroof.password_changed')]);
    }

    public function sessions(Request $request): JsonResponse
    {
        /** @var PersonalAccessToken|TransientToken $current */
        $current = $request->user()->currentAccessToken();

        $tokens = $request->user()->tokens()->latest('last_used_at')->get()->map(fn (PersonalAccessToken $token) => [
            'id' => $token->id,
            'name' => $token->name,
            'last_used_at' => $token->last_used_at?->toIso8601String(),
            'created_at' => $token->created_at?->toIso8601String(),
            'expires_at' => $token->expires_at?->toIso8601String(),
            'current' => $current instanceof PersonalAccessToken && $current->getKey() === $token->getKey(),
        ]);

        return response()->json(['data' => $tokens]);
    }

    public function revokeSession(Request $request, int $session): JsonResponse
    {
        $request->user()->tokens()->whereKey($session)->firstOrFail()->delete();

        return response()->json(null, 204);
    }

    public function destroy(Request $request): JsonResponse
    {
        $request->validate(['password' => ['required', 'string', 'current_password:sanctum']]);

        $user = $request->user();
        $user->tokens()->delete();
        // Permanently remove the account and all owned financial data (cascades).
        $user->forceDelete();

        return response()->json(null, 204);
    }
}
