<?php

namespace Tests\Feature;

use App\Models\Account;
use App\Models\Category;
use App\Models\User;
use App\Services\TransactionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class BudgetTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    private Account $wallet;

    private Category $transport;

    private Category $fuel;

    private Category $food;

    protected function setUp(): void
    {
        parent::setUp();
        $this->travelTo(Carbon::parse('2026-09-16 09:00', 'UTC'));
        $this->user = $this->signIn(User::factory()->create(['timezone' => 'Asia/Hebron', 'currency' => 'ILS']));
        $this->wallet = $this->account($this->user, ['currency' => 'ILS', 'opening_balance' => 10_000_00]);
        $this->transport = $this->category($this->user, 'expense', ['name' => 'Transport']);
        $this->fuel = $this->category($this->user, 'expense', ['name' => 'Fuel', 'parent_id' => $this->transport->id]);
        $this->food = $this->category($this->user, 'expense', ['name' => 'Food']);
    }

    private function spend(Category $category, int $minor, string $when, string $type = 'expense', ?Account $account = null): void
    {
        app(TransactionService::class)->create($this->user, [
            'type' => $type, 'account_id' => ($account ?? $this->wallet)->id, 'category_id' => $category->id,
            'amount' => $minor, 'occurred_at' => Carbon::parse($when, 'UTC'),
        ]);
    }

    public function test_category_budget_progress_includes_subcategories_and_ignores_other_spending(): void
    {
        $this->spend($this->transport, 100_00, '2026-09-02 10:00');
        $this->spend($this->fuel, 260_00, '2026-09-10 10:00');
        $this->spend($this->food, 999_00, '2026-09-10 10:00');
        $this->spend($this->transport, 50_00, '2026-08-30 10:00'); // previous month
        $usd = $this->account($this->user, ['currency' => 'USD']);
        $this->spend($this->transport, 70_00, '2026-09-11 10:00', account: $usd); // other currency

        $this->postJson('/api/v1/budgets', [
            'name' => 'Transport', 'period' => 'monthly', 'currency' => 'ILS', 'amount' => '500',
            'category_ids' => [$this->transport->id],
        ])->assertCreated()
            ->assertJsonPath('data.alert_thresholds', [50, 75, 90, 100])
            ->assertJsonPath('data.progress.period', ['start' => '2026-09-01', 'end' => '2026-09-30'])
            ->assertJsonPath('data.progress.spent', '360.00')
            ->assertJsonPath('data.progress.remaining', '140.00')
            ->assertJsonPath('data.progress.percent', 72)
            ->assertJsonPath('data.progress.days_left', 15)
            // 140.00 / 15 days = 9.33
            ->assertJsonPath('data.progress.safe_to_spend_daily', '9.33')
            ->assertJsonPath('data.progress.reached_thresholds', [50])
            ->assertJsonPath('data.progress.status', 'warning');
    }

    public function test_total_budget_covers_all_expenses_and_exceeded_status(): void
    {
        $this->spend($this->food, 800_00, '2026-09-05 10:00');
        $this->spend($this->transport, 300_00, '2026-09-06 10:00');

        $this->postJson('/api/v1/budgets', ['name' => 'Everything', 'period' => 'monthly', 'currency' => 'ILS', 'amount' => '1000', 'alert_thresholds' => [80, 100]])
            ->assertCreated()
            ->assertJsonPath('data.progress.spent_minor', 1_100_00)
            ->assertJsonPath('data.progress.remaining_minor', -100_00)
            ->assertJsonPath('data.progress.safe_to_spend_daily_minor', 0)
            ->assertJsonPath('data.progress.status', 'exceeded')
            ->assertJsonPath('data.progress.reached_thresholds', [80, 100]);
    }

    public function test_weekly_and_custom_periods(): void
    {
        $this->spend($this->food, 40_00, '2026-09-13 10:00'); // this week (week starts Saturday 12th)
        $this->spend($this->food, 25_00, '2026-09-11 10:00'); // last week

        $this->postJson('/api/v1/budgets', ['name' => 'Week', 'period' => 'weekly', 'currency' => 'ILS', 'amount' => '100'])
            ->assertJsonPath('data.progress.period', ['start' => '2026-09-12', 'end' => '2026-09-18'])
            ->assertJsonPath('data.progress.spent_minor', 40_00);

        $this->postJson('/api/v1/budgets', ['name' => 'Trip', 'period' => 'custom', 'currency' => 'ILS', 'amount' => '100', 'starts_on' => '2026-09-10', 'ends_on' => '2026-09-13'])
            ->assertJsonPath('data.progress.spent_minor', 65_00)
            ->assertJsonPath('data.progress.days_left', 0);
    }

    public function test_budget_follows_financial_month_start(): void
    {
        $this->user->settingsOrDefault()->forceFill(['month_start_day' => 10])->save();
        $this->spend($this->food, 10_00, '2026-09-09 10:00');
        $this->spend($this->food, 20_00, '2026-09-12 10:00');

        $this->postJson('/api/v1/budgets', ['name' => 'Food', 'period' => 'monthly', 'currency' => 'ILS', 'amount' => '100'])
            ->assertJsonPath('data.progress.period', ['start' => '2026-09-10', 'end' => '2026-10-09'])
            ->assertJsonPath('data.progress.spent_minor', 20_00);
    }

    public function test_validation(): void
    {
        $income = $this->category($this->user, 'income');
        $foreign = Category::factory()->create();

        $this->postJson('/api/v1/budgets', ['name' => '', 'period' => 'yearly', 'currency' => 'XXX', 'amount' => '-1', 'alert_thresholds' => [50, 50, 0]])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['name', 'period', 'currency', 'alert_thresholds.1', 'alert_thresholds.2']);

        $this->postJson('/api/v1/budgets', ['name' => 'x', 'period' => 'custom', 'currency' => 'ILS', 'amount' => '10'])
            ->assertUnprocessable()->assertJsonValidationErrors(['starts_on', 'ends_on']);

        $this->postJson('/api/v1/budgets', ['name' => 'x', 'period' => 'monthly', 'currency' => 'JOD', 'amount' => '10.1234'])
            ->assertUnprocessable()->assertJsonValidationErrors('amount');

        $this->postJson('/api/v1/budgets', ['name' => 'x', 'period' => 'monthly', 'currency' => 'ILS', 'amount' => '10', 'category_ids' => [$income->id]])
            ->assertUnprocessable()->assertJsonValidationErrors('category_ids');

        $this->postJson('/api/v1/budgets', ['name' => 'x', 'period' => 'monthly', 'currency' => 'ILS', 'amount' => '10', 'category_ids' => [$foreign->id]])
            ->assertUnprocessable()->assertJsonValidationErrors('category_ids.0');
    }

    public function test_update_archive_delete_and_ownership(): void
    {
        $id = $this->postJson('/api/v1/budgets', ['name' => 'Food', 'period' => 'monthly', 'currency' => 'ILS', 'amount' => '100'])->json('data.id');

        $this->patchJson("/api/v1/budgets/{$id}", ['amount' => '250', 'category_ids' => [$this->food->id], 'alert_thresholds' => [90]])
            ->assertOk()
            ->assertJsonPath('data.amount', '250.00')
            ->assertJsonPath('data.category_ids', [$this->food->id])
            ->assertJsonPath('data.alert_thresholds', [90]);

        $this->patchJson("/api/v1/budgets/{$id}", ['archived' => true])->assertOk()->assertJsonPath('data.archived', true);
        $this->getJson('/api/v1/budgets')->assertJsonCount(0, 'data');
        $this->getJson('/api/v1/budgets?include_archived=1')->assertJsonCount(1, 'data');

        $this->signIn();
        $this->getJson("/api/v1/budgets/{$id}")->assertNotFound();
        $this->deleteJson("/api/v1/budgets/{$id}")->assertNotFound();
    }
}
