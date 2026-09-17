<?php

namespace Tests\Feature;

use App\Models\User;
use App\Notifications\BudgetThresholdReached;
use App\Notifications\GoalBehindSchedule;
use App\Notifications\SpendingSummary;
use App\Services\AlertChecker;
use App\Services\TransactionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class NotificationTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->travelTo(Carbon::parse('2026-09-16 09:00', 'UTC'));
        $this->user = $this->signIn(User::factory()->create(['timezone' => 'Asia/Hebron', 'currency' => 'ILS', 'locale' => 'en']));
    }

    private function spend(int $minor, string $when = '2026-09-10 10:00'): void
    {
        $account = $this->user->accounts()->first() ?? $this->account($this->user, ['currency' => 'ILS']);
        $category = $this->user->categories()->first() ?? $this->category($this->user);
        app(TransactionService::class)->create($this->user, [
            'type' => 'expense', 'account_id' => $account->id, 'category_id' => $category->id,
            'amount' => $minor, 'occurred_at' => Carbon::parse($when, 'UTC'),
        ]);
    }

    public function test_budget_alert_is_sent_once_for_the_highest_threshold_crossed(): void
    {
        Notification::fake();
        $this->postJson('/api/v1/budgets', ['name' => 'Food', 'period' => 'monthly', 'currency' => 'ILS', 'amount' => '100'])->assertCreated();

        $this->spend(80_00); // jumps past 50 and 75 at once
        $this->spend(1_00);

        Notification::assertSentToTimes($this->user, BudgetThresholdReached::class, 1);
        Notification::assertSentTo($this->user, BudgetThresholdReached::class, fn ($n) => $n->threshold === 75);

        $this->spend(15_00); // crosses 90
        Notification::assertSentToTimes($this->user, BudgetThresholdReached::class, 2);
    }

    public function test_disabled_budget_alerts_send_nothing(): void
    {
        Notification::fake();
        $this->patchJson('/api/v1/settings', ['budget_alerts' => false])->assertOk();
        $this->postJson('/api/v1/budgets', ['name' => 'Food', 'period' => 'monthly', 'currency' => 'ILS', 'amount' => '100']);

        $this->spend(99_00);

        Notification::assertNothingSent();
    }

    public function test_inbox_lists_localized_notifications_and_marks_read(): void
    {
        $this->postJson('/api/v1/budgets', ['name' => 'Food', 'period' => 'monthly', 'currency' => 'ILS', 'amount' => '100']);
        $this->spend(95_00);

        $inbox = $this->getJson('/api/v1/notifications')->assertOk()
            ->assertJsonPath('meta.unread_count', 1)
            ->assertJsonPath('data.0.type', 'budget_threshold')
            ->assertJsonPath('data.0.title', 'Food budget at 90%')
            ->assertJsonPath('data.0.body', "You have spent ₪ \u{2066}95.00\u{2069} of your ₪ \u{2066}100.00\u{2069} Food budget.")
            ->assertJsonPath('data.0.action', '/budgets');
        $id = $inbox->json('data.0.id');

        $this->withHeader('Accept-Language', 'ar')->getJson('/api/v1/notifications')
            ->assertJsonPath('data.0.title', 'ميزانية Food وصلت إلى 90%')
            ->assertJsonPath('data.0.body', "أنفقت \u{2066}95.00\u{2069} ₪ من ميزانية Food البالغة \u{2066}100.00\u{2069} ₪.");

        $this->postJson("/api/v1/notifications/{$id}/read")->assertOk()->assertJsonPath('data.read', true);
        $this->getJson('/api/v1/notifications?unread=1')->assertJsonCount(0, 'data');
        $this->deleteJson("/api/v1/notifications/{$id}")->assertNoContent();

        $this->signIn();
        $this->postJson("/api/v1/notifications/{$id}/read")->assertNotFound();
    }

    public function test_preferences_control_channels(): void
    {
        $this->getJson('/api/v1/notification-preferences')->assertOk()
            ->assertJsonPath('data.monthly_summary', ['in_app' => true, 'email' => true])
            ->assertJsonPath('data.budget_threshold', ['in_app' => true, 'email' => false]);

        $this->putJson('/api/v1/notification-preferences', ['preferences' => ['budget_threshold' => ['in_app' => false, 'email' => true]]])
            ->assertOk()
            ->assertJsonPath('data.budget_threshold', ['in_app' => false, 'email' => true]);

        $this->putJson('/api/v1/notification-preferences', ['preferences' => ['spam' => ['email' => true]]])->assertUnprocessable();

        Notification::fake();
        $this->postJson('/api/v1/budgets', ['name' => 'Food', 'period' => 'monthly', 'currency' => 'ILS', 'amount' => '100']);
        $this->spend(60_00);
        Notification::assertSentTo($this->user, BudgetThresholdReached::class, fn ($n, array $channels) => $channels === ['mail']);
    }

    public function test_goal_reminder_when_behind_schedule(): void
    {
        Notification::fake();
        $this->postJson('/api/v1/goals', ['name' => 'Laptop', 'currency' => 'ILS', 'target_amount' => '6000', 'target_date' => '2027-03-16'])->assertCreated();

        $checker = app(AlertChecker::class);
        $this->assertSame(1, $checker->goals($this->user));
        $this->assertSame(0, $checker->goals($this->user));

        Notification::assertSentTo($this->user, GoalBehindSchedule::class, fn ($n) => $n->monthlyNeeded === 1_000_00 && $n->currency === 'ILS');
    }

    public function test_weekly_and_monthly_summaries(): void
    {
        Notification::fake();
        $this->spend(120_00, '2026-08-20 10:00');
        $this->spend(45_00, '2026-09-08 10:00');

        // 2026-09-12 is a Saturday (week start) — weekly summary for 5–11 Sep.
        $this->travelTo(Carbon::parse('2026-09-12 05:30', 'UTC'));
        $this->assertSame(1, app(AlertChecker::class)->summaries($this->user));

        // 2026-10-01: monthly summary for September.
        $this->travelTo(Carbon::parse('2026-10-01 05:30', 'UTC'));
        $this->assertSame(1, app(AlertChecker::class)->summaries($this->user->refresh()));
        $this->assertSame(0, app(AlertChecker::class)->summaries($this->user));

        Notification::assertSentTo($this->user, SpendingSummary::class, fn ($n) => $n->period === 'weekly');
        Notification::assertSentTo($this->user, SpendingSummary::class, fn ($n) => $n->period === 'monthly' && $n->expense === 45_00);
    }

    public function test_scheduled_command_runs(): void
    {
        $this->artisan('masroof:send-notifications --all')->assertSuccessful();
    }
}
