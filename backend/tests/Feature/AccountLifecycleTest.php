<?php

namespace Tests\Feature;

use App\Models\User;
use App\Notifications\VerifyEmailNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\URL;
use Tests\TestCase;

class AccountLifecycleTest extends TestCase
{
    use RefreshDatabase;

    public function test_registration_sends_a_verification_email_with_a_working_signed_link(): void
    {
        Notification::fake();

        $this->postJson('/api/v1/auth/register', [
            'name' => 'Lina', 'email' => 'lina@example.com', 'password' => 'secret123',
            'password_confirmation' => 'secret123', 'currency' => 'ILS', 'device_name' => 'phone',
        ])->assertCreated()->assertJsonPath('user.email_verified', false)->assertJsonPath('user.currency', 'ILS');

        $user = User::query()->where('email', 'lina@example.com')->firstOrFail();
        $url = null;
        Notification::assertSentTo($user, VerifyEmailNotification::class, function (VerifyEmailNotification $n) use ($user, &$url) {
            $url = $n->toMail($user)->actionUrl;

            return true;
        });

        $this->get($url)->assertRedirectContains('/verify-email?status=verified');
        $this->assertTrue($user->refresh()->hasVerifiedEmail());
    }

    public function test_tampered_verification_links_are_rejected(): void
    {
        $user = User::factory()->unverified()->create();
        $url = URL::temporarySignedRoute('v1.auth.verification.verify', now()->addHour(), ['id' => $user->id, 'hash' => sha1('other@example.com')]);

        $this->get($url)->assertRedirectContains('status=invalid');
        $this->get(str_replace('signature=', 'signature=x', $url))->assertForbidden();
        $this->assertFalse($user->refresh()->hasVerifiedEmail());
    }

    public function test_verification_email_can_be_resent(): void
    {
        Notification::fake();
        $user = $this->signIn(User::factory()->unverified()->create());

        $this->postJson('/api/v1/auth/email/verification-notification')->assertAccepted();
        Notification::assertSentTo($user, VerifyEmailNotification::class);
    }

    public function test_token_refresh_rotates_the_token(): void
    {
        $user = User::factory()->create();
        $old = $user->createToken('phone')->plainTextToken;

        $new = $this->withToken($old)->postJson('/api/v1/auth/refresh')->assertOk()->json('token');

        $this->assertNotSame($old, $new);
        $this->assertSame(1, $user->tokens()->count());
        $this->app['auth']->forgetGuards();
        $this->withToken($old)->getJson('/api/v1/me')->assertUnauthorized();
        $this->app['auth']->forgetGuards();
        $this->withToken($new)->getJson('/api/v1/me')->assertOk();
    }

    public function test_onboarding_saves_optional_answers_and_completes(): void
    {
        $user = $this->signIn();
        $this->getJson('/api/v1/settings')->assertJsonPath('data.settings.onboarding_completed', false);

        $this->postJson('/api/v1/onboarding', [
            'name' => 'Omar', 'locale' => 'ar', 'currency' => 'JOD',
            'monthly_income_estimate' => '850.500', 'main_goal' => 'emergency_fund', 'budget_alerts' => false,
        ])->assertOk()
            ->assertJsonPath('data.currency', 'JOD')
            ->assertJsonPath('data.settings.monthly_income_estimate', '850.500')
            ->assertJsonPath('data.settings.monthly_income_estimate_minor', 850500)
            ->assertJsonPath('data.settings.budget_alerts', false)
            ->assertJsonPath('data.settings.recurring_reminders', true)
            ->assertJsonPath('data.settings.onboarding_completed', true);

        // Everything optional: skipping all questions still completes onboarding.
        $other = $this->signIn();
        $this->postJson('/api/v1/onboarding', [])->assertOk()->assertJsonPath('data.settings.onboarding_completed', true);
        $this->assertNotSame($user->id, $other->id);
    }

    public function test_settings_validation(): void
    {
        $this->signIn();
        $foreign = $this->account(User::factory()->create());

        $this->patchJson('/api/v1/settings', [
            'month_start_day' => 31, 'main_goal' => 'get_rich', 'monthly_income_estimate' => '10.123',
            'default_account_id' => $foreign->id, 'currency' => 'XYZ',
        ])->assertUnprocessable()->assertJsonValidationErrors(['month_start_day', 'main_goal', 'default_account_id', 'currency']);

        $this->patchJson('/api/v1/settings', ['monthly_income_estimate' => '10.123'])
            ->assertUnprocessable()->assertJsonValidationErrors('monthly_income_estimate');
    }

    public function test_settings_update_default_account_and_month_start(): void
    {
        $user = $this->signIn();
        $account = $this->account($user);

        $this->patchJson('/api/v1/settings', ['default_account_id' => $account->id, 'month_start_day' => 25])
            ->assertOk()
            ->assertJsonPath('data.settings.default_account_id', $account->id)
            ->assertJsonPath('data.settings.month_start_day', 25);
    }
}
