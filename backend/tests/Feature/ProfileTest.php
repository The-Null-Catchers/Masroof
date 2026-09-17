<?php

namespace Tests\Feature;

use App\Models\Account;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ProfileTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_update_preferences(): void
    {
        $this->signIn();

        $this->patchJson('/api/v1/me', ['name' => 'New Name', 'locale' => 'en', 'currency' => 'KWD', 'timezone' => 'Asia/Kuwait', 'week_start' => 0])
            ->assertOk()
            ->assertJsonPath('data.locale', 'en')
            ->assertJsonPath('data.currency', 'KWD')
            ->assertJsonPath('data.week_start', 0);
    }

    public function test_preferences_are_validated(): void
    {
        $this->signIn();

        $this->patchJson('/api/v1/me', ['locale' => 'fr', 'timezone' => 'Mars/Base', 'week_start' => 9])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['locale', 'timezone', 'week_start']);
    }

    public function test_role_cannot_be_escalated_through_profile_update(): void
    {
        $user = $this->signIn();

        $this->patchJson('/api/v1/me', ['role' => 'admin', 'suspended_at' => null])->assertOk();

        $this->assertFalse($user->refresh()->isAdmin());
    }

    public function test_changing_password_requires_current_password_and_revokes_other_devices(): void
    {
        $user = User::factory()->create(['password' => 'secret123']);
        $current = $user->createToken('current')->plainTextToken;
        $user->createToken('other');

        $this->withToken($current)->putJson('/api/v1/me/password', [
            'current_password' => 'wrong-one1',
            'password' => 'newsecret1',
            'password_confirmation' => 'newsecret1',
        ])->assertUnprocessable()->assertJsonValidationErrors('current_password');

        $this->withToken($current)->putJson('/api/v1/me/password', [
            'current_password' => 'secret123',
            'password' => 'newsecret1',
            'password_confirmation' => 'newsecret1',
        ])->assertOk();

        $this->assertTrue(Hash::check('newsecret1', $user->refresh()->password));
        $this->assertSame(['current'], $user->tokens()->pluck('name')->all());
    }

    public function test_user_can_list_and_revoke_sessions_but_not_other_users_sessions(): void
    {
        $user = User::factory()->create();
        $current = $user->createToken('current')->plainTextToken;
        $other = $user->createToken('tablet');
        $stranger = User::factory()->create()->createToken('stranger');

        $this->withToken($current)->getJson('/api/v1/me/sessions')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonFragment(['name' => 'current', 'current' => true]);

        $this->withToken($current)->deleteJson("/api/v1/me/sessions/{$stranger->accessToken->id}")->assertNotFound();
        $this->withToken($current)->deleteJson("/api/v1/me/sessions/{$other->accessToken->id}")->assertNoContent();
        $this->assertSame(['current'], $user->tokens()->pluck('name')->all());
    }

    public function test_user_can_permanently_delete_their_account_and_data(): void
    {
        Storage::fake('local');
        $user = User::factory()->create(['password' => 'secret123']);
        Account::factory()->for($user)->create();
        Storage::disk('local')->put("receipts/{$user->id}/photo.jpg", 'jpeg');
        Storage::disk('local')->put("exports/{$user->id}/report.pdf", 'pdf');
        Storage::disk('local')->put('receipts/someone-else/photo.jpg', 'jpeg');
        $token = $user->createToken('phone')->plainTextToken;

        $this->withToken($token)->deleteJson('/api/v1/me', ['password' => 'bad'])->assertUnprocessable();
        $this->withToken($token)->deleteJson('/api/v1/me', ['password' => 'secret123'])->assertNoContent();

        $this->assertDatabaseMissing('users', ['id' => $user->id]);
        $this->assertDatabaseMissing('accounts', ['user_id' => $user->id]);
        Storage::disk('local')->assertMissing("receipts/{$user->id}/photo.jpg");
        Storage::disk('local')->assertMissing("exports/{$user->id}/report.pdf");
        Storage::disk('local')->assertExists('receipts/someone-else/photo.jpg');
    }
}
