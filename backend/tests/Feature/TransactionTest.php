<?php

namespace Tests\Feature;

use App\Models\Account;
use App\Models\Category;
use App\Models\Transaction;
use App\Models\User;
use App\Services\TransactionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Illuminate\Testing\TestResponse;
use Tests\TestCase;

class TransactionTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    private Account $bank;

    private Category $food;

    private Category $salary;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = $this->signIn();
        $this->bank = $this->account($this->user, ['currency' => 'SAR', 'opening_balance' => 1_000_00]);
        $this->food = $this->category($this->user, 'expense');
        $this->salary = $this->category($this->user, 'income');
    }

    /** @param  array<string, mixed>  $overrides */
    private function expense(array $overrides = []): TestResponse
    {
        return $this->postJson('/api/v1/transactions', $overrides + [
            'type' => 'expense',
            'account_id' => $this->bank->id,
            'category_id' => $this->food->id,
            'amount' => '45.50',
            'occurred_at' => '2026-09-10T12:30:00+03:00',
            'merchant' => 'Al Baik',
        ]);
    }

    public function test_expense_decreases_balance(): void
    {
        $this->expense()->assertCreated()
            ->assertJsonPath('data.amount', '45.50')
            ->assertJsonPath('data.amount_minor', 4550)
            ->assertJsonPath('data.currency', 'SAR')
            ->assertJsonPath('data.occurred_at', '2026-09-10T09:30:00+00:00')
            ->assertJsonPath('data.category.id', $this->food->id);

        $this->assertSame(954_50, $this->bank->refresh()->balance);
    }

    public function test_income_increases_balance(): void
    {
        $this->expense(['type' => 'income', 'category_id' => $this->salary->id, 'amount' => '12000'])->assertCreated();

        $this->assertSame(13_000_00, $this->bank->refresh()->balance);
    }

    public function test_amount_rules(): void
    {
        $this->expense(['amount' => '0'])->assertUnprocessable()->assertJsonValidationErrors('amount');
        $this->expense(['amount' => '-5'])->assertUnprocessable()->assertJsonValidationErrors('amount');
        $this->expense(['amount' => '1.999'])->assertUnprocessable()->assertJsonValidationErrors('amount');
        $this->expense(['amount' => 'abc'])->assertUnprocessable()->assertJsonValidationErrors('amount');
        $this->expense(['amount' => '1000000001'])->assertUnprocessable()->assertJsonValidationErrors('amount');
        $this->expense(['amount' => 19.99])->assertCreated()->assertJsonPath('data.amount_minor', 1999);
    }

    public function test_category_is_required_and_must_match_type(): void
    {
        $this->expense(['category_id' => null])->assertUnprocessable()->assertJsonValidationErrors('category_id');
        $this->expense(['category_id' => $this->salary->id])->assertUnprocessable()->assertJsonValidationErrors('category_id');
    }

    public function test_cannot_use_another_users_account_or_category(): void
    {
        $foreignAccount = Account::factory()->create();
        $foreignCategory = Category::factory()->create();

        $this->expense(['account_id' => $foreignAccount->id])->assertUnprocessable()->assertJsonValidationErrors('account_id');
        $this->expense(['category_id' => $foreignCategory->id])->assertUnprocessable()->assertJsonValidationErrors('category_id');
        $this->assertSame(0, $foreignAccount->refresh()->balance);
    }

    public function test_cannot_add_to_archived_account(): void
    {
        $this->bank->forceFill(['archived_at' => now()])->save();

        $this->expense()->assertUnprocessable()->assertJsonValidationErrors('account_id');
    }

    public function test_validation_messages_are_localized_in_arabic(): void
    {
        $this->withHeader('Accept-Language', 'ar')
            ->expense(['amount' => '1.999'])
            ->assertUnprocessable()
            ->assertJsonPath('errors.amount.0', 'أدخل مبلغًا صحيحًا بحد أقصى 2 خانات عشرية.');
    }

    public function test_updating_amount_adjusts_balance_by_the_difference(): void
    {
        $id = $this->expense(['amount' => '100'])->json('data.id');

        $this->patchJson("/api/v1/transactions/{$id}", ['amount' => '30.25'])->assertOk()->assertJsonPath('data.amount', '30.25');

        $this->assertSame(969_75, $this->bank->refresh()->balance);
    }

    public function test_moving_a_transaction_between_accounts_updates_both(): void
    {
        $cash = $this->account($this->user, ['currency' => 'SAR', 'opening_balance' => 200_00]);
        $id = $this->expense(['amount' => '50'])->json('data.id');

        $this->patchJson("/api/v1/transactions/{$id}", ['account_id' => $cash->id])->assertOk();

        $this->assertSame(1_000_00, $this->bank->refresh()->balance);
        $this->assertSame(150_00, $cash->refresh()->balance);
    }

    public function test_moving_to_an_account_with_another_currency_requires_a_new_amount(): void
    {
        $usd = $this->account($this->user, ['currency' => 'USD']);
        $id = $this->expense(['amount' => '50'])->json('data.id');

        $this->patchJson("/api/v1/transactions/{$id}", ['account_id' => $usd->id])
            ->assertUnprocessable()->assertJsonValidationErrors('amount');

        $this->patchJson("/api/v1/transactions/{$id}", ['account_id' => $usd->id, 'amount' => '13.33'])
            ->assertOk()->assertJsonPath('data.currency', 'USD');
        $this->assertSame(-13_33, $usd->refresh()->balance);
        $this->assertSame(1_000_00, $this->bank->refresh()->balance);
    }

    public function test_changing_type_from_expense_to_income_flips_the_effect(): void
    {
        $id = $this->expense(['amount' => '10'])->json('data.id');

        $this->patchJson("/api/v1/transactions/{$id}", ['type' => 'income'])
            ->assertUnprocessable()->assertJsonValidationErrors('category_id');

        $this->patchJson("/api/v1/transactions/{$id}", ['type' => 'income', 'category_id' => $this->salary->id])->assertOk();
        $this->assertSame(1_010_00, $this->bank->refresh()->balance);
    }

    public function test_deleting_restores_balance(): void
    {
        $id = $this->expense(['amount' => '99.99'])->json('data.id');

        $this->deleteJson("/api/v1/transactions/{$id}")->assertNoContent();

        $this->assertSame(1_000_00, $this->bank->refresh()->balance);
        $this->assertSoftDeleted('transactions', ['id' => $id]);
    }

    public function test_same_currency_transfer_moves_money_between_accounts(): void
    {
        $cash = $this->account($this->user, ['currency' => 'SAR']);

        $this->postJson('/api/v1/transactions', [
            'type' => 'transfer', 'account_id' => $this->bank->id, 'transfer_account_id' => $cash->id,
            'amount' => '250', 'transfer_amount' => '999', 'occurred_at' => now()->toIso8601String(),
        ])->assertCreated()
            ->assertJsonPath('data.transfer_amount', '250.00')
            ->assertJsonPath('data.category_id', null);

        $this->assertSame(750_00, $this->bank->refresh()->balance);
        $this->assertSame(250_00, $cash->refresh()->balance);
    }

    public function test_cross_currency_transfer_requires_and_uses_received_amount(): void
    {
        $kwd = $this->account($this->user, ['currency' => 'KWD']);
        $payload = ['type' => 'transfer', 'account_id' => $this->bank->id, 'transfer_account_id' => $kwd->id, 'amount' => '100', 'occurred_at' => now()->toIso8601String()];

        $this->postJson('/api/v1/transactions', $payload)->assertUnprocessable()->assertJsonValidationErrors('transfer_amount');
        $this->postJson('/api/v1/transactions', $payload + ['transfer_amount' => '8.1234'])->assertUnprocessable()->assertJsonValidationErrors('transfer_amount');

        $this->postJson('/api/v1/transactions', $payload + ['transfer_amount' => '8.123'])
            ->assertCreated()
            ->assertJsonPath('data.transfer_amount', '8.123')
            ->assertJsonPath('data.transfer_currency', 'KWD');

        $this->assertSame(900_00, $this->bank->refresh()->balance);
        $this->assertSame(8_123, $kwd->refresh()->balance);
    }

    public function test_transfer_rules(): void
    {
        $cash = $this->account($this->user, ['currency' => 'SAR']);
        $base = ['type' => 'transfer', 'account_id' => $this->bank->id, 'amount' => '5', 'occurred_at' => now()->toIso8601String()];

        $this->postJson('/api/v1/transactions', $base)->assertUnprocessable()->assertJsonValidationErrors('transfer_account_id');
        $this->postJson('/api/v1/transactions', $base + ['transfer_account_id' => $this->bank->id])->assertUnprocessable()->assertJsonValidationErrors('transfer_account_id');
        $this->postJson('/api/v1/transactions', $base + ['transfer_account_id' => $cash->id, 'category_id' => $this->food->id])->assertUnprocessable()->assertJsonValidationErrors('category_id');
        $this->expense(['transfer_account_id' => $cash->id])->assertUnprocessable()->assertJsonValidationErrors('transfer_account_id');
    }

    public function test_converting_a_transfer_to_an_expense_releases_the_destination(): void
    {
        $cash = $this->account($this->user, ['currency' => 'SAR']);
        $id = $this->postJson('/api/v1/transactions', [
            'type' => 'transfer', 'account_id' => $this->bank->id, 'transfer_account_id' => $cash->id, 'amount' => '60', 'occurred_at' => now()->toIso8601String(),
        ])->json('data.id');

        $this->patchJson("/api/v1/transactions/{$id}", ['type' => 'expense', 'category_id' => $this->food->id])
            ->assertOk()
            ->assertJsonPath('data.transfer_account_id', null);

        $this->assertSame(940_00, $this->bank->refresh()->balance);
        $this->assertSame(0, $cash->refresh()->balance);
    }

    public function test_foreign_transactions_are_not_found(): void
    {
        $other = User::factory()->create();
        $account = $this->account($other);
        $category = $this->category($other);
        $foreign = app(TransactionService::class)->create($other, [
            'type' => 'expense', 'account_id' => $account->id, 'category_id' => $category->id, 'amount' => 100, 'occurred_at' => now(),
        ]);

        $this->getJson("/api/v1/transactions/{$foreign->id}")->assertNotFound();
        $this->patchJson("/api/v1/transactions/{$foreign->id}", ['amount' => '1'])->assertNotFound();
        $this->deleteJson("/api/v1/transactions/{$foreign->id}")->assertNotFound();
        $this->assertSame(-100, $account->refresh()->balance);
    }

    public function test_client_generated_id_makes_create_idempotent(): void
    {
        $id = strtolower((string) Str::ulid());

        $this->expense(['id' => $id])->assertCreated();
        $this->expense(['id' => $id])->assertOk();

        $this->assertSame(1, Transaction::query()->count());
        $this->assertSame(954_50, $this->bank->refresh()->balance);
    }

    public function test_listing_supports_filters_search_and_pagination(): void
    {
        $cash = $this->account($this->user, ['currency' => 'SAR']);
        $this->expense(['merchant' => 'Starbucks', 'occurred_at' => '2026-08-01T10:00:00Z']);
        $this->expense(['merchant' => 'Panda', 'note' => 'weekly groceries 100%', 'occurred_at' => '2026-08-15T10:00:00Z']);
        $this->expense(['type' => 'income', 'category_id' => $this->salary->id, 'merchant' => 'Employer', 'occurred_at' => '2026-08-27T10:00:00Z']);
        $this->postJson('/api/v1/transactions', ['type' => 'transfer', 'account_id' => $this->bank->id, 'transfer_account_id' => $cash->id, 'amount' => '5', 'occurred_at' => '2026-08-20T10:00:00Z']);

        $this->getJson('/api/v1/transactions')->assertOk()->assertJsonCount(4, 'data')
            ->assertJsonPath('data.0.merchant', 'Employer')
            ->assertJsonStructure(['data', 'links', 'meta' => ['current_page', 'last_page', 'total']]);
        $this->getJson('/api/v1/transactions?type=expense')->assertJsonCount(2, 'data');
        $this->getJson('/api/v1/transactions?search=star')->assertJsonCount(1, 'data');
        $this->getJson('/api/v1/transactions?search=100%25')->assertJsonCount(1, 'data');
        $this->getJson('/api/v1/transactions?from=2026-08-10&to=2026-08-20')->assertJsonCount(2, 'data');
        $this->getJson("/api/v1/transactions?account_id={$cash->id}")->assertJsonCount(1, 'data');
        $this->getJson('/api/v1/transactions?per_page=2&sort=occurred_at')->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.merchant', 'Starbucks')->assertJsonPath('meta.last_page', 2);
        $this->getJson('/api/v1/transactions?per_page=500')->assertUnprocessable();
    }

    public function test_category_filter_includes_subcategories(): void
    {
        $child = $this->category($this->user, 'expense', ['parent_id' => $this->food->id]);
        $this->expense();
        $this->expense(['category_id' => $child->id]);

        $this->getJson("/api/v1/transactions?category_id={$this->food->id}")->assertJsonCount(2, 'data');
    }

    public function test_maintained_balances_always_match_a_full_recalculation(): void
    {
        $service = app(TransactionService::class);
        $cash = $this->account($this->user, ['currency' => 'SAR', 'opening_balance' => 50_00]);
        $usd = $this->account($this->user, ['currency' => 'USD', 'opening_balance' => 10_00]);
        $accounts = [$this->bank, $cash];
        mt_srand(42);
        $created = [];

        foreach (range(1, 60) as $i) {
            $roll = mt_rand(1, 10);
            $account = $accounts[mt_rand(0, 1)];
            $data = match (true) {
                $roll <= 5 => ['type' => 'expense', 'account_id' => $account->id, 'category_id' => $this->food->id],
                $roll <= 7 => ['type' => 'income', 'account_id' => $account->id, 'category_id' => $this->salary->id],
                $roll <= 9 => ['type' => 'transfer', 'account_id' => $this->bank->id, 'transfer_account_id' => $cash->id],
                default => ['type' => 'transfer', 'account_id' => $cash->id, 'transfer_account_id' => $usd->id, 'transfer_amount' => mt_rand(1, 5000)],
            };
            $created[] = $service->create($this->user, $data + ['amount' => mt_rand(1, 100_000), 'occurred_at' => now()]);

            if ($i % 7 === 0) {
                $service->update($created[array_rand($created)], ['amount' => mt_rand(1, 100_000)]);
            }
            if ($i % 11 === 0) {
                $victim = array_splice($created, array_rand($created), 1)[0];
                $service->delete($victim);
            }
        }

        foreach ([$this->bank, $cash, $usd] as $account) {
            $maintained = $account->refresh()->balance;
            $this->assertSame($maintained, $service->recalculate($account), "Balance drift on {$account->currency} account");
        }
    }
}
