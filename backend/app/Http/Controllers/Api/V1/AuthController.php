<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\LoginRequest;
use App\Http\Requests\Api\V1\RegisterRequest;
use App\Http\Resources\V1\UserResource;
use App\Models\User;
use App\Services\DefaultCategories;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Auth\Events\Registered;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password as PasswordRule;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(RegisterRequest $request, DefaultCategories $defaults): JsonResponse
    {
        $user = DB::transaction(function () use ($request, $defaults) {
            $user = User::query()->create($request->safe()->except('device_name'));
            $defaults->provision($user);

            return $user;
        });

        event(new Registered($user));

        return $this->tokenResponse($user, $request->string('device_name')->toString(), 201);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $user = User::query()->where('email', $request->input('email'))->first();

        // Always hash-check to keep response timing uniform for unknown emails.
        $valid = Hash::check($request->input('password'), $user->password ?? '$2y$12$'.str_repeat('a', 53));

        if (! $user || ! $valid) {
            throw ValidationException::withMessages(['email' => __('auth.failed')]);
        }

        if ($user->isSuspended()) {
            throw ValidationException::withMessages(['email' => __('masroof.account_suspended')]);
        }

        $user->forceFill(['last_login_at' => now()])->save();

        return $this->tokenResponse($user, $request->string('device_name')->toString());
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(null, 204);
    }

    /**
     * Rotates the current token: issues a fresh one and revokes the old one.
     */
    public function refresh(Request $request): JsonResponse
    {
        $user = $request->user();
        $current = $user->currentAccessToken();
        $response = $this->tokenResponse($user, $current->name ?? 'device');
        $current->delete();

        return $response;
    }

    public function forgotPassword(Request $request): JsonResponse
    {
        $request->validate(['email' => ['required', 'email']]);

        Password::sendResetLink(['email' => mb_strtolower(trim($request->string('email')))]);

        // Identical response whether or not the address exists (no account enumeration).
        return response()->json(['message' => __('passwords.sent')]);
    }

    public function resetPassword(Request $request): JsonResponse
    {
        $request->validate([
            'token' => ['required', 'string'],
            'email' => ['required', 'email'],
            'password' => ['required', 'string', 'confirmed', PasswordRule::min(8)->letters()->numbers()],
        ]);

        $status = Password::reset(
            [
                'email' => mb_strtolower(trim($request->string('email'))),
                'password' => $request->input('password'),
                'password_confirmation' => $request->input('password_confirmation'),
                'token' => $request->input('token'),
            ],
            function (User $user, string $password) {
                $user->forceFill(['password' => $password, 'remember_token' => Str::random(60)])->save();
                // Sign out every device after a reset.
                $user->tokens()->delete();
                event(new PasswordReset($user));
            },
        );

        if ($status !== Password::PASSWORD_RESET) {
            throw ValidationException::withMessages(['email' => __($status)]);
        }

        return response()->json(['message' => __($status)]);
    }

    private function tokenResponse(User $user, string $deviceName, int $status = 200): JsonResponse
    {
        $ttl = config('masroof.token_ttl_minutes');
        $token = $user->createToken($deviceName, ['*'], $ttl ? now()->addMinutes((int) $ttl) : null);

        return response()->json([
            'token' => $token->plainTextToken,
            'token_type' => 'Bearer',
            'expires_at' => $token->accessToken->expires_at?->toIso8601String(),
            'user' => new UserResource($user->refresh()),
        ], $status);
    }
}
