<?php

namespace Tests\Feature;

use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Tests\TestCase;

class AdminTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();
        $this->admin = User::factory()->create(['role' => UserRole::Admin]);
    }

    public function test_admin_endpoints_are_hidden_from_regular_users(): void
    {
        $this->signIn();

        foreach (['stats', 'users', 'system', 'failed-jobs', 'audit-log'] as $path) {
            $this->getJson("/api/v1/admin/{$path}")->assertNotFound();
        }
    }

    public function test_stats_are_aggregate_counts_without_financial_data(): void
    {
        $user = User::factory()->create(['suspended_at' => now()]);
        $account = $this->account($user, ['currency' => 'ILS', 'opening_balance' => 123456]);
        $this->signIn($this->admin);

        $response = $this->getJson('/api/v1/admin/stats')
            ->assertOk()
            ->assertJsonPath('data.users.total', 2)
            ->assertJsonPath('data.users.suspended', 1)
            ->assertJsonCount(30, 'data.users.signups_by_day');

        $body = $response->getContent();
        $this->assertStringNotContainsString('123456', (string) $body);
        $this->assertStringNotContainsString($account->name, (string) $body);
    }

    public function test_user_list_is_searchable_and_exposes_no_finances(): void
    {
        User::factory()->create(['name' => 'Omar Khalil', 'email' => 'omar@example.com']);
        User::factory()->create(['name' => 'Sara', 'email' => 'sara@example.com', 'email_verified_at' => null]);
        $this->signIn($this->admin);

        $this->getJson('/api/v1/admin/users?search=OMAR')
            ->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.email', 'omar@example.com')
            ->assertJsonMissingPath('data.0.balance')
            ->assertJsonStructure(['data' => [['id', 'name', 'email', 'role', 'email_verified', 'suspended', 'last_active_at', 'created_at']]]);

        $this->getJson('/api/v1/admin/users?status=unverified')->assertJsonPath('meta.total', 1);
    }

    public function test_suspend_revokes_sessions_and_reactivate_restores_access(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('phone')->plainTextToken;
        $this->signIn($this->admin);

        $this->postJson("/api/v1/admin/users/{$user->id}/suspend", ['reason' => 'Chargeback abuse'])
            ->assertOk()
            ->assertJsonPath('data.suspended', true);
        $this->assertSame(0, $user->tokens()->count());
        $this->assertDatabaseHas('admin_audit_logs', ['action' => 'user.suspended', 'target_user_id' => $user->id, 'admin_id' => $this->admin->id]);

        $this->app['auth']->forgetGuards();
        $this->withToken($token)->getJson('/api/v1/me')->assertUnauthorized();

        $this->signIn($this->admin);
        $this->postJson("/api/v1/admin/users/{$user->id}/reactivate")->assertOk()->assertJsonPath('data.suspended', false);
        $this->getJson('/api/v1/admin/audit-log')->assertOk()->assertJsonPath('data.0.action', 'user.reactivated');
    }

    public function test_admins_cannot_suspend_themselves_or_other_admins(): void
    {
        $other = User::factory()->create(['role' => UserRole::Admin]);
        $this->signIn($this->admin);

        $this->postJson("/api/v1/admin/users/{$this->admin->id}/suspend")->assertUnprocessable();
        $this->postJson("/api/v1/admin/users/{$other->id}/suspend")->assertUnprocessable();
    }

    public function test_failed_jobs_hide_payloads_and_can_be_deleted(): void
    {
        $uuid = (string) Str::uuid();
        DB::table('failed_jobs')->insert([
            'uuid' => $uuid, 'connection' => 'redis', 'queue' => 'default',
            'payload' => json_encode(['displayName' => 'App\\Jobs\\ProcessReceipt', 'attempts' => 2, 'data' => ['secret' => 'merchant-xyz']]),
            'exception' => "RuntimeException: OCR engine crashed\n#0 /var/www/stack",
            'failed_at' => now(),
        ]);
        $this->signIn($this->admin);

        $this->getJson('/api/v1/admin/system')->assertOk()->assertJsonPath('data.queue.failed', 1)->assertJsonPath('data.database', true);
        $response = $this->getJson('/api/v1/admin/failed-jobs')
            ->assertOk()
            ->assertJsonPath('data.0.job', 'ProcessReceipt')
            ->assertJsonPath('data.0.error', 'RuntimeException: OCR engine crashed');
        $this->assertStringNotContainsString('merchant-xyz', (string) $response->getContent());

        $this->deleteJson("/api/v1/admin/failed-jobs/{$uuid}")->assertNoContent();
        $this->deleteJson("/api/v1/admin/failed-jobs/{$uuid}")->assertNotFound();
        $this->assertDatabaseHas('admin_audit_logs', ['action' => 'job.deleted']);
    }

    public function test_admin_role_is_granted_only_from_the_console(): void
    {
        $user = User::factory()->create(['email' => 'ops@example.com']);

        $this->artisan('masroof:admin', ['email' => 'ops@example.com'])->assertSuccessful();
        $this->assertSame(UserRole::Admin, $user->refresh()->role);

        $this->signIn($user);
        $this->patchJson('/api/v1/me', ['role' => 'user'])->assertOk();
        $this->assertSame(UserRole::Admin, $user->refresh()->role);

        $this->artisan('masroof:admin', ['email' => 'ops@example.com', '--revoke' => true])->assertSuccessful();
        $this->assertSame(UserRole::User, $user->refresh()->role);
    }
}
