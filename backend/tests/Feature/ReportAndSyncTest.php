<?php

namespace Tests\Feature;

use App\Models\Account;
use App\Models\User;
use App\Services\TransactionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class ReportAndSyncTest extends TestCase
{
    use RefreshDatabase;

    public function test_summary_totals_breakdown_and_series_respect_user_timezone(): void
    {
        $user = $this->signIn();
        $user->forceFill(['timezone' => 'Asia/Riyadh'])->save();
        $service = app(TransactionService::class);
        $bank = $this->account($user, ['currency' => 'SAR']);
        $cash = $this->account($user, ['currency' => 'SAR']);
        $food = $this->category($user, 'expense', ['name' => 'Food']);
        $restaurants = $this->category($user, 'expense', ['name' => 'Restaurants', 'parent_id' => $food->id]);
        $salary = $this->category($user, 'income', ['name' => 'Salary']);

        $service->create($user, ['type' => 'income', 'account_id' => $bank->id, 'category_id' => $salary->id, 'amount' => 10_000_00, 'occurred_at' => Carbon::parse('2026-09-01 09:00', 'Asia/Riyadh')]);
        $service->create($user, ['type' => 'expense', 'account_id' => $bank->id, 'category_id' => $food->id, 'amount' => 100_00, 'occurred_at' => Carbon::parse('2026-09-02 12:00', 'Asia/Riyadh')]);
        // 23:30 UTC on Sep 2 is 02:30 on Sep 3 in Riyadh.
        $service->create($user, ['type' => 'expense', 'account_id' => $bank->id, 'category_id' => $restaurants->id, 'amount' => 50_50, 'occurred_at' => Carbon::parse('2026-09-02 23:30', 'UTC')]);
        // Transfers are neither income nor expense.
        $service->create($user, ['type' => 'transfer', 'account_id' => $bank->id, 'transfer_account_id' => $cash->id, 'amount' => 500_00, 'occurred_at' => Carbon::parse('2026-09-02 12:00', 'Asia/Riyadh')]);
        // Outside range.
        $service->create($user, ['type' => 'expense', 'account_id' => $bank->id, 'category_id' => $food->id, 'amount' => 999_00, 'occurred_at' => Carbon::parse('2026-10-01 12:00', 'Asia/Riyadh')]);

        $response = $this->getJson('/api/v1/reports/summary?from=2026-09-01&to=2026-09-30')->assertOk();

        $response->assertJsonPath('data.interval', 'day')
            ->assertJsonPath('data.totals.0.income', '10000.00')
            ->assertJsonPath('data.totals.0.expense', '150.50')
            ->assertJsonPath('data.totals.0.net', '9849.50')
            ->assertJsonPath('data.totals.0.count', 3);

        $foodRow = collect($response->json('data.by_category'))->firstWhere('category_id', $food->id);
        $this->assertSame('150.50', $foodRow['total']);
        $this->assertSame(2, $foodRow['count']);

        $periods = collect($response->json('data.series'))->pluck('expense', 'period')->all();
        $this->assertSame(['2026-09-01' => '0.00', '2026-09-02' => '100.00', '2026-09-03' => '50.50'], $periods);
    }

    public function test_summary_is_isolated_per_user(): void
    {
        $other = User::factory()->create();
        $account = Account::factory()->for($other)->create();
        $category = $this->category($other);
        app(TransactionService::class)->create($other, ['type' => 'expense', 'account_id' => $account->id, 'category_id' => $category->id, 'amount' => 100, 'occurred_at' => now()]);

        $this->signIn();
        $this->getJson('/api/v1/reports/summary?from='.now()->subDay()->toDateString().'&to='.now()->addDay()->toDateString())
            ->assertOk()
            ->assertJsonCount(0, 'data.totals');
    }

    public function test_sync_pull_returns_changes_and_deletions_since_cursor(): void
    {
        $user = $this->signIn();
        $service = app(TransactionService::class);
        $account = $this->account($user);
        $category = $this->category($user);
        $first = $service->create($user, ['type' => 'expense', 'account_id' => $account->id, 'category_id' => $category->id, 'amount' => 100, 'occurred_at' => now()]);

        $initial = $this->getJson('/api/v1/sync')->assertOk()
            ->assertJsonPath('has_more', false)
            ->assertJsonCount(1, 'accounts.upserted')
            ->assertJsonCount(1, 'transactions.upserted');
        $cursor = $initial->json('server_time');

        $this->travel(5)->seconds();
        $second = $service->create($user, ['type' => 'expense', 'account_id' => $account->id, 'category_id' => $category->id, 'amount' => 200, 'occurred_at' => now()]);
        $service->delete($first);

        $delta = $this->getJson('/api/v1/sync?since='.urlencode($cursor))->assertOk();

        $this->assertSame([$second->id], collect($delta->json('transactions.upserted'))->pluck('id')->all());
        $this->assertSame([$first->id], $delta->json('transactions.deleted'));
        $this->assertSame([$account->id], collect($delta->json('accounts.upserted'))->pluck('id')->all());
        $this->assertSame(0, count($delta->json('categories.upserted')));
    }
}
