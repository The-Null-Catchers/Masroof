<?php

namespace Tests\Feature;

use App\Models\User;
use App\Notifications\ResetPasswordNotification as ResetPassword;
use App\Services\DefaultCategories;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Illuminate\Testing\TestResponse;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    private function register(array $overrides = []): TestResponse
    {
        return $this->postJson('/api/v1/auth/register', $overrides + [
            'name' => 'Sara Ahmed',
            'email' => 'Sara@Example.com',
            'password' => 'secret123',
            'password_confirmation' => 'secret123',
            'locale' => 'ar',
            'currency' => 'SAR',
            'device_name' => 'iPhone',
        ]);
    }

    public function test_user_can_register_and_receives_token_and_default_categories(): void
    {
        $response = $this->register()->assertCreated()
            ->assertJsonStructure(['token', 'token_type', 'expires_at', 'user' => ['id', 'email', 'locale', 'currency']])
            ->assertJsonPath('user.email', 'sara@example.com')
            ->assertJsonPath('user.role', 'user');

        $user = User::query()->where('email', 'sara@example.com')->firstOrFail();
        $this->assertCount(count(DefaultCategories::DEFINITIONS), $user->categories);
        $this->assertSame('الطعام والمطاعم', $user->categories()->where('default_key', 'food')->value('name'));

        $this->withToken($response->json('token'))->getJson('/api/v1/me')->assertOk()->assertJsonPath('data.id', $user->id);
    }

    public function test_registration_validates_input(): void
    {
        User::factory()->create(['email' => 'taken@example.com']);

        $this->register(['email' => 'taken@example.com', 'password' => 'short', 'currency' => 'XYZ'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['email', 'password', 'currency']);
    }

    public function test_password_is_never_exposed(): void
    {
        $this->register()->assertCreated()->assertJsonMissingPath('user.password');
    }

    public function test_user_can_log_in_with_valid_credentials(): void
    {
        User::factory()->create(['email' => 'ali@example.com', 'password' => 'secret123']);

        $this->postJson('/api/v1/auth/login', ['email' => 'ALI@example.com ', 'password' => 'secret123', 'device_name' => 'web'])
            ->assertOk()
            ->assertJsonStructure(['token', 'user']);
    }

    public function test_login_fails_with_the_same_message_for_wrong_password_or_unknown_email(): void
    {
        User::factory()->create(['email' => 'ali@example.com', 'password' => 'secret123']);

        $wrong = $this->postJson('/api/v1/auth/login', ['email' => 'ali@example.com', 'password' => 'nope12345', 'device_name' => 'web'])
            ->assertUnprocessable()->json('errors.email.0');
        $unknown = $this->postJson('/api/v1/auth/login', ['email' => 'ghost@example.com', 'password' => 'nope12345', 'device_name' => 'web'])
            ->assertUnprocessable()->json('errors.email.0');

        $this->assertSame($wrong, $unknown);
    }

    public function test_login_errors_are_localized(): void
    {
        $this->withHeader('Accept-Language', 'ar')
            ->postJson('/api/v1/auth/login', ['email' => 'ghost@example.com', 'password' => 'nope12345', 'device_name' => 'web'])
            ->assertUnprocessable()
            ->assertHeader('Content-Language', 'ar')
            ->assertJsonPath('errors.email.0', 'البريد الإلكتروني أو كلمة المرور غير صحيحة.');
    }

    public function test_login_is_rate_limited(): void
    {
        foreach (range(1, 5) as $ignored) {
            $this->postJson('/api/v1/auth/login', ['email' => 'ghost@example.com', 'password' => 'bad', 'device_name' => 'x']);
        }

        $this->postJson('/api/v1/auth/login', ['email' => 'ghost@example.com', 'password' => 'bad', 'device_name' => 'x'])
            ->assertTooManyRequests();
    }

    public function test_suspended_users_cannot_log_in_or_use_existing_tokens(): void
    {
        $user = User::factory()->create(['email' => 'blocked@example.com', 'password' => 'secret123']);
        $token = $user->createToken('phone')->plainTextToken;
        $user->forceFill(['suspended_at' => now()])->save();

        $this->postJson('/api/v1/auth/login', ['email' => 'blocked@example.com', 'password' => 'secret123', 'device_name' => 'web'])
            ->assertUnprocessable();
        $this->withToken($token)->getJson('/api/v1/me')->assertForbidden();
        $this->assertSame(0, $user->tokens()->count());
    }

    public function test_logout_revokes_only_the_current_token(): void
    {
        $user = User::factory()->create();
        $phone = $user->createToken('phone')->plainTextToken;
        $user->createToken('laptop');

        $this->withToken($phone)->postJson('/api/v1/auth/logout')->assertNoContent();

        $this->assertSame(['laptop'], $user->tokens()->pluck('name')->all());
    }

    public function test_expired_tokens_are_rejected(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('phone', ['*'], now()->subMinute())->plainTextToken;

        $this->withToken($token)->getJson('/api/v1/me')->assertUnauthorized();
    }

    public function test_protected_routes_require_authentication(): void
    {
        $this->getJson('/api/v1/accounts')->assertUnauthorized();
        $this->getJson('/api/v1/transactions')->assertUnauthorized();
    }

    public function test_forgot_password_does_not_reveal_whether_the_email_exists(): void
    {
        Notification::fake();
        $user = User::factory()->create(['email' => 'real@example.com']);

        $known = $this->postJson('/api/v1/auth/forgot-password', ['email' => 'real@example.com'])->assertOk()->json();
        $unknown = $this->postJson('/api/v1/auth/forgot-password', ['email' => 'ghost@example.com'])->assertOk()->json();

        $this->assertSame($known, $unknown);
        Notification::assertSentTo($user, ResetPassword::class);
    }

    public function test_password_can_be_reset_with_a_valid_token_and_signs_out_all_devices(): void
    {
        Notification::fake();
        $user = User::factory()->create(['email' => 'real@example.com']);
        $user->createToken('old-device');

        $this->postJson('/api/v1/auth/forgot-password', ['email' => 'real@example.com']);

        $token = null;
        Notification::assertSentTo($user, ResetPassword::class, function (ResetPassword $notification) use (&$token) {
            $token = $notification->token;

            return true;
        });

        $this->postJson('/api/v1/auth/reset-password', [
            'token' => $token,
            'email' => 'real@example.com',
            'password' => 'brandnew99',
            'password_confirmation' => 'brandnew99',
        ])->assertOk();

        $this->assertTrue(Hash::check('brandnew99', $user->refresh()->password));
        $this->assertSame(0, $user->tokens()->count());
    }

    public function test_reset_password_rejects_invalid_tokens(): void
    {
        User::factory()->create(['email' => 'real@example.com']);

        $this->postJson('/api/v1/auth/reset-password', [
            'token' => 'invalid',
            'email' => 'real@example.com',
            'password' => 'brandnew99',
            'password_confirmation' => 'brandnew99',
        ])->assertUnprocessable()->assertJsonValidationErrors('email');
    }
}
