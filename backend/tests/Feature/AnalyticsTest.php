<?php

namespace Tests\Feature;

use App\Models\Account;
use App\Models\Category;
use App\Models\User;
use App\Services\Insights\InsightEngine;
use App\Services\TransactionService;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class AnalyticsTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    private Account $wallet;

    private Category $restaurants;

    private Category $rent;

    private Category $salary;

    protected function setUp(): void
    {
        parent::setUp();
        $this->travelTo(Carbon::parse('2026-09-20 09:00', 'UTC'));
        $this->user = $this->signIn(User::factory()->create(['timezone' => 'Asia/Hebron', 'currency' => 'ILS']));
        $this->wallet = $this->account($this->user, ['currency' => 'ILS', 'opening_balance' => 1_000_00]);
        $this->restaurants = $this->category($this->user, 'expense', ['name' => 'Restaurants']);
        $this->rent = $this->category($this->user, 'expense', ['name' => 'Rent', 'is_fixed' => true]);
        $this->salary = $this->category($this->user, 'income', ['name' => 'Salary']);
    }

    private function tx(string $type, ?Category $category, int $minor, string $when, ?string $merchant = null, ?Account $account = null): string
    {
        return app(TransactionService::class)->create($this->user, [
            'type' => $type, 'account_id' => ($account ?? $this->wallet)->id, 'category_id' => $category?->id,
            'amount' => $minor, 'occurred_at' => Carbon::parse($when, 'UTC'), 'merchant' => $merchant,
        ])->id;
    }

    private function seedTwoMonths(): void
    {
        // August
        $this->tx('income', $this->salary, 10_000_00, '2026-08-01 08:00');
        $this->tx('expense', $this->rent, 3_000_00, '2026-08-02 08:00', 'Landlord');
        $this->tx('expense', $this->restaurants, 500_00, '2026-08-10 12:00', 'Zaytouna');
        // September
        $this->tx('income', $this->salary, 10_000_00, '2026-09-01 08:00');
        $this->tx('expense', $this->rent, 3_000_00, '2026-09-02 08:00', 'Landlord');
        $this->tx('expense', $this->restaurants, 350_00, '2026-09-05 12:00', 'Zaytouna');
        $this->tx('expense', $this->restaurants, 240_00, '2026-09-12 12:00', 'zaytouna');
        $this->tx('expense', $this->restaurants, 100_00, '2026-09-14 12:00', 'Falafel House');
    }

    public function test_summary_totals_rates_changes_and_breakdowns(): void
    {
        $this->seedTwoMonths();
        $usd = $this->account($this->user, ['currency' => 'USD']);
        $this->tx('expense', $this->restaurants, 99_00, '2026-09-15 12:00', 'Elsewhere', $usd);

        $data = $this->getJson('/api/v1/analytics/summary')->assertOk()->json('data');

        $this->assertSame('ILS', $data['currency']);
        $this->assertSame(['start' => '2026-09-01', 'end' => '2026-09-30'], $data['period']);
        $this->assertSame(10_000_00, $data['income']);
        $this->assertSame(3_690_00, $data['expense']);
        $this->assertSame(6_310_00, $data['savings']);
        $this->assertEquals(63.1, $data['savings_rate']);
        // 3690.00 over 20 elapsed days
        $this->assertSame(184_50, $data['average_daily_spending']);
        $this->assertEquals(5.4, $data['changes']['expense']);
        $this->assertSame(['fixed' => 3_000_00, 'variable' => 690_00], $data['fixed_vs_variable']);

        $restaurants = collect($data['categories'])->firstWhere('category_id', $this->restaurants->id);
        $this->assertSame(690_00, $restaurants['total']);
        $this->assertEquals(38.0, $restaurants['change']);

        $this->assertSame(3_000_00, $data['largest_expenses'][0]['amount']);
        $this->assertSame(['merchant' => 'Zaytouna', 'count' => 2, 'total' => 590_00], $data['top_merchants'][0]);
    }

    public function test_trends_include_closing_balances(): void
    {
        $this->seedTwoMonths();

        $months = $this->getJson('/api/v1/analytics/trends?months=3')->assertOk()->json('data.months');

        $this->assertCount(3, $months);
        $this->assertSame('2026-07', $months[0]['label']);
        $this->assertSame(0, $months[0]['income']);
        $this->assertSame(1_000_00, $months[0]['closing_balance']);
        $this->assertSame(1_000_00 + 10_000_00 - 3_500_00, $months[1]['closing_balance']);
        $this->assertSame($this->wallet->refresh()->balance, $months[2]['closing_balance']);
    }

    public function test_insight_engine_rules(): void
    {
        $this->seedTwoMonths();
        // Duplicate-looking charge
        $this->tx('expense', $this->restaurants, 45_00, '2026-09-18 12:00', 'Coffee Lab');
        $this->tx('expense', $this->restaurants, 45_00, '2026-09-19 09:00', 'Coffee Lab');
        // Subscription increase across 3 months
        $this->tx('expense', $this->rent, 40_00, '2026-07-05 08:00', 'StreamFlix');
        $this->tx('expense', $this->rent, 40_00, '2026-08-05 08:00', 'StreamFlix');
        $this->tx('expense', $this->rent, 50_00, '2026-09-05 08:00', 'StreamFlix');
        // Budget at risk
        $this->postJson('/api/v1/budgets', ['name' => 'Eating out', 'period' => 'monthly', 'currency' => 'ILS', 'amount' => '1000', 'category_ids' => [$this->restaurants->id]])->assertCreated();

        $keys = collect(app(InsightEngine::class)->generate($this->user->refresh()))->map->key;

        $this->assertContains('possible_duplicate', $keys);
        $this->assertContains('subscription_increase', $keys);
        $this->assertContains('budget_at_risk', $keys);
        $this->assertContains('savings_rate', $keys);
        $this->assertContains('category_spending_increased', $keys);
        // Highest priority first.
        $this->assertSame('possible_duplicate', $keys->first());
    }

    public function test_frequent_merchants_are_not_mistaken_for_subscriptions(): void
    {
        foreach (['2026-07', '2026-08', '2026-09'] as $month) {
            $this->tx('expense', $this->restaurants, 100_00, "{$month}-03 12:00", 'Supermarket');
            $this->tx('expense', $this->restaurants, 180_00, "{$month}-12 12:00", 'Supermarket');
        }
        $this->tx('expense', $this->restaurants, 90_00, '2026-06-25 12:00', 'Gym');
        $this->tx('expense', $this->restaurants, 150_00, '2026-07-25 12:00', 'Gym');
        $this->tx('expense', $this->restaurants, 160_00, '2026-08-25 12:00', 'Gym');

        $keys = collect(app(InsightEngine::class)->generate($this->user))->map->key;

        $this->assertNotContains('subscription_increase', $keys);
    }

    public function test_insight_messages_are_localized(): void
    {
        $this->tx('income', $this->salary, 1_000_00, '2026-09-01 08:00');
        $this->tx('expense', $this->restaurants, 950_00, '2026-09-02 08:00');

        $this->withHeader('Accept-Language', 'ar')->getJson('/api/v1/insights')
            ->assertOk()
            ->assertJsonFragment(['key' => 'savings_rate_low', 'message' => 'نسبة ادخارك هذا الشهر 5% فقط.']);
    }

    public function test_unusual_spending_and_large_purchase(): void
    {
        foreach (['2026-06', '2026-07', '2026-08'] as $month) {
            foreach (range(1, 5) as $day) {
                $this->tx('expense', $this->restaurants, 40_00, "{$month}-0{$day} 12:00", 'Cafe');
            }
        }
        // 200/month history; September already 20 days in with a big purchase.
        $this->tx('expense', $this->restaurants, 1_200_00, '2026-09-17 12:00', 'Electronics Store');

        $insights = collect(app(InsightEngine::class)->generate($this->user, 'ILS', CarbonImmutable::parse('2026-09-20 09:00', 'UTC')));

        $unusual = $insights->firstWhere('key', 'unusual_spending');
        $this->assertNotNull($unusual);
        $this->assertSame('warning', $unusual->severity);
        $this->assertNotNull($insights->firstWhere('key', 'large_purchase'));
    }

    public function test_dashboard_aggregates_everything(): void
    {
        $this->seedTwoMonths();
        $this->postJson('/api/v1/budgets', ['name' => 'Monthly', 'period' => 'monthly', 'currency' => 'ILS', 'amount' => '5000'])->assertCreated();
        $this->postJson('/api/v1/goals', ['name' => 'Laptop', 'currency' => 'ILS', 'target_amount' => '4000', 'target_date' => '2027-01-01'])->assertCreated();

        $this->getJson('/api/v1/dashboard')
            ->assertOk()
            ->assertJsonPath('data.currency', 'ILS')
            ->assertJsonPath('data.month.income_minor', 10_000_00)
            ->assertJsonPath('data.month.expense_minor', 3_690_00)
            ->assertJsonPath('data.budget.remaining_minor', 1_310_00)
            ->assertJsonPath('data.goals.0.name', 'Laptop')
            ->assertJsonCount(6, 'data.monthly_trend')
            ->assertJsonCount(6, 'data.recent_transactions')
            ->assertJsonStructure(['data' => ['net_worth', 'spending_by_category', 'insights', 'budgets']]);
    }

    public function test_analytics_are_isolated_per_user(): void
    {
        $this->seedTwoMonths();
        $this->signIn();

        $this->getJson('/api/v1/analytics/summary')->assertJsonPath('data.expense', 0);
        $this->getJson('/api/v1/insights')->assertJsonCount(0, 'data');
    }
}
