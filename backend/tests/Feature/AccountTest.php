<?php

namespace Tests\Feature;

use App\Models\Account;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class AccountTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_create_an_account_with_opening_balance(): void
    {
        $this->signIn();

        $this->postJson('/api/v1/accounts', [
            'name' => 'الراجحي', 'type' => 'bank', 'currency' => 'sar', 'opening_balance' => '1500.50', 'color' => '#0F7A68',
        ])->assertCreated()
            ->assertJsonPath('data.name', 'الراجحي')
            ->assertJsonPath('data.currency', 'SAR')
            ->assertJsonPath('data.balance', '1500.50')
            ->assertJsonPath('data.balance_minor', 150050);
    }

    public function test_numeric_opening_balance_is_accepted_without_float_rounding(): void
    {
        $this->signIn();

        $this->postJson('/api/v1/accounts', ['name' => 'Cash', 'type' => 'cash', 'currency' => 'USD', 'opening_balance' => 0.29])
            ->assertCreated()
            ->assertJsonPath('data.balance_minor', 29);
    }

    public function test_opening_balance_precision_follows_currency(): void
    {
        $this->signIn();

        $this->postJson('/api/v1/accounts', ['name' => 'NBK', 'type' => 'bank', 'currency' => 'KWD', 'opening_balance' => '10.125'])
            ->assertCreated()->assertJsonPath('data.balance', '10.125');

        $this->postJson('/api/v1/accounts', ['name' => 'Bad', 'type' => 'bank', 'currency' => 'SAR', 'opening_balance' => '10.125'])
            ->assertUnprocessable()->assertJsonValidationErrors('opening_balance');
    }

    public function test_account_input_is_validated(): void
    {
        $this->signIn();

        $this->postJson('/api/v1/accounts', ['name' => '', 'type' => 'crypto', 'currency' => 'XXX', 'color' => 'red'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['name', 'type', 'currency', 'color']);
    }

    public function test_listing_only_returns_own_active_accounts(): void
    {
        $user = $this->signIn();
        $this->account($user, ['name' => 'Mine']);
        Account::factory()->for($user)->archived()->create(['name' => 'Old']);
        Account::factory()->create(['name' => 'Someone else']);

        $this->getJson('/api/v1/accounts')->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.name', 'Mine');
        $this->getJson('/api/v1/accounts?include_archived=1')->assertOk()->assertJsonCount(2, 'data');
    }

    public function test_foreign_accounts_are_not_found(): void
    {
        $this->signIn();
        $foreign = Account::factory()->create();

        $this->getJson("/api/v1/accounts/{$foreign->id}")->assertNotFound();
        $this->patchJson("/api/v1/accounts/{$foreign->id}", ['name' => 'Hacked'])->assertNotFound();
        $this->deleteJson("/api/v1/accounts/{$foreign->id}")->assertNotFound();
        $this->assertDatabaseHas('accounts', ['id' => $foreign->id, 'deleted_at' => null]);
    }

    public function test_changing_opening_balance_recalculates_balance(): void
    {
        $user = $this->signIn();
        $account = $this->account($user, ['opening_balance' => 10_000]);
        $category = $this->category($user);

        $this->postJson('/api/v1/transactions', [
            'type' => 'expense', 'account_id' => $account->id, 'category_id' => $category->id, 'amount' => '25', 'occurred_at' => now()->toIso8601String(),
        ])->assertCreated();

        $this->patchJson("/api/v1/accounts/{$account->id}", ['opening_balance' => '500'])
            ->assertOk()
            ->assertJsonPath('data.balance', '475.00');
    }

    public function test_currency_cannot_change_once_transactions_exist(): void
    {
        $user = $this->signIn();
        $account = $this->account($user);
        $category = $this->category($user);

        $this->patchJson("/api/v1/accounts/{$account->id}", ['currency' => 'USD'])->assertOk();

        $this->postJson('/api/v1/transactions', [
            'type' => 'expense', 'account_id' => $account->id, 'category_id' => $category->id, 'amount' => '5', 'occurred_at' => now()->toIso8601String(),
        ])->assertCreated();

        $this->patchJson("/api/v1/accounts/{$account->id}", ['currency' => 'EUR'])
            ->assertUnprocessable()->assertJsonValidationErrors('currency');
    }

    public function test_account_can_be_archived_and_restored(): void
    {
        $user = $this->signIn();
        $account = $this->account($user);

        $this->patchJson("/api/v1/accounts/{$account->id}", ['archived' => true])->assertOk()->assertJsonPath('data.archived', true);
        $this->patchJson("/api/v1/accounts/{$account->id}", ['archived' => false])->assertOk()->assertJsonPath('data.archived', false);
    }

    public function test_create_with_client_id_is_idempotent(): void
    {
        $this->signIn();
        $id = (string) Str::ulid();
        $payload = ['id' => $id, 'name' => 'Offline', 'type' => 'cash', 'currency' => 'SAR'];

        $this->postJson('/api/v1/accounts', $payload)->assertCreated()->assertJsonPath('data.id', $id);
        $this->postJson('/api/v1/accounts', $payload)->assertOk()->assertJsonPath('data.id', $id);
        $this->assertSame(1, Account::query()->count());
    }

    public function test_client_id_owned_by_another_user_conflicts(): void
    {
        $foreign = Account::factory()->create();
        $this->signIn();

        $this->postJson('/api/v1/accounts', ['id' => $foreign->id, 'name' => 'X', 'type' => 'cash', 'currency' => 'SAR'])
            ->assertConflict();
    }

    public function test_deleting_an_account_reverses_transfers_into_other_accounts(): void
    {
        $user = $this->signIn();
        $source = $this->account($user, ['opening_balance' => 100_00]);
        $destination = $this->account($user, ['opening_balance' => 0]);

        $this->postJson('/api/v1/transactions', [
            'type' => 'transfer', 'account_id' => $source->id, 'transfer_account_id' => $destination->id,
            'amount' => '40', 'occurred_at' => now()->toIso8601String(),
        ])->assertCreated();
        $this->assertSame(40_00, $destination->refresh()->balance);

        $this->deleteJson("/api/v1/accounts/{$source->id}")->assertNoContent();

        $this->assertSoftDeleted($source);
        $this->assertSame(0, $destination->refresh()->balance);
    }

    public function test_net_worth_summary_groups_by_currency_and_respects_flags(): void
    {
        $user = $this->signIn();
        $this->account($user, ['currency' => 'SAR', 'opening_balance' => 100_00]);
        $this->account($user, ['currency' => 'SAR', 'opening_balance' => 50_25]);
        $this->account($user, ['currency' => 'USD', 'opening_balance' => 10_00]);
        $this->account($user, ['currency' => 'SAR', 'opening_balance' => 999_00, 'include_in_total' => false]);
        Account::factory()->for($user)->archived()->create(['currency' => 'SAR', 'balance' => 777_00]);
        $this->account(User::factory()->create(), ['currency' => 'SAR', 'opening_balance' => 1_000_00]);

        $this->getJson('/api/v1/accounts/summary')
            ->assertOk()
            ->assertJsonCount(2, 'data.net_worth')
            ->assertJsonFragment(['currency' => 'SAR', 'total' => '150.25', 'accounts' => 2])
            ->assertJsonFragment(['currency' => 'USD', 'total' => '10.00', 'accounts' => 1]);
    }
}
