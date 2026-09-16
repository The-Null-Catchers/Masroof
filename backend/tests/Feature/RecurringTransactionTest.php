<?php

namespace Tests\Feature;

use App\Models\Account;
use App\Models\Category;
use App\Models\RecurringTransaction;
use App\Models\Transaction;
use App\Models\User;
use App\Notifications\RecurringPaymentDue;
use App\Services\RecurringService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Notification;
use Illuminate\Testing\TestResponse;
use Tests\TestCase;

class RecurringTransactionTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    private Account $bank;

    private Category $rent;

    private Category $salary;

    protected function setUp(): void
    {
        parent::setUp();
        $this->travelTo(Carbon::parse('2026-09-16 09:00', 'UTC'));
        $this->user = $this->signIn(User::factory()->create(['timezone' => 'Asia/Hebron', 'currency' => 'ILS']));
        $this->bank = $this->account($this->user, ['currency' => 'ILS', 'opening_balance' => 10_000_00]);
        $this->rent = $this->category($this->user, 'expense', ['name' => 'Rent']);
        $this->salary = $this->category($this->user, 'income', ['name' => 'Salary']);
    }

    /** @param array<string, mixed> $overrides */
    private function rule(array $overrides = []): TestResponse
    {
        return $this->postJson('/api/v1/recurring', $overrides + [
            'name' => 'Rent', 'type' => 'expense', 'account_id' => $this->bank->id, 'category_id' => $this->rent->id,
            'amount' => '2800', 'frequency' => 'monthly', 'starts_on' => '2026-10-02', 'merchant' => 'Landlord',
        ]);
    }

    public function test_future_rule_is_scheduled_without_creating_transactions(): void
    {
        $this->rule()->assertCreated()
            ->assertJsonPath('data.next_occurrence_on', '2026-10-02')
            ->assertJsonPath('data.upcoming', ['2026-10-02', '2026-11-02', '2026-12-02'])
            ->assertJsonPath('data.amount', '2800.00');

        $this->assertSame(0, Transaction::query()->count());
    }

    public function test_past_start_generates_every_missed_occurrence_once(): void
    {
        $id = $this->rule(['starts_on' => '2026-07-02'])->assertCreated()->assertJsonPath('data.next_occurrence_on', '2026-10-02')->json('data.id');

        $generated = Transaction::query()->where('recurring_transaction_id', $id)->orderBy('occurred_at')->get();
        $this->assertSame(['2026-07-02', '2026-08-02', '2026-09-02'], $generated->map(fn ($t) => $t->recurring_occurrence_on->toDateString())->all());
        $this->assertSame(10_000_00 - 3 * 2_800_00, $this->bank->refresh()->balance);
        // Local noon in Hebron is 09:00 UTC in summer.
        $this->assertSame('2026-07-02 09:00:00', $generated->first()->occurred_at->toDateTimeString());

        // Running again (e.g. overlapping scheduler runs) creates nothing new.
        $rule = RecurringTransaction::query()->findOrFail($id);
        $this->assertSame(0, app(RecurringService::class)->process($rule));
        $rule->forceFill(['next_occurrence_on' => '2026-08-02'])->save();
        $this->assertSame(0, app(RecurringService::class)->process($rule->refresh()));
        $this->assertSame(3, Transaction::query()->where('recurring_transaction_id', $id)->count());
        $this->assertSame('2026-10-02', $rule->refresh()->next_occurrence_on->toDateString());
    }

    public function test_scheduler_command_generates_due_transactions(): void
    {
        $id = $this->rule(['starts_on' => '2026-09-20', 'type' => 'income', 'category_id' => $this->salary->id, 'amount' => '9200', 'name' => 'Salary'])->json('data.id');

        $this->travelTo(Carbon::parse('2026-09-20 06:00', 'UTC'));
        $this->artisan('masroof:process-recurring')->assertSuccessful();

        $this->assertSame(1, Transaction::query()->where('recurring_transaction_id', $id)->count());
        $this->assertSame(10_000_00 + 9_200_00, $this->bank->refresh()->balance);
    }

    public function test_remind_mode_notifies_once_and_never_creates_transactions(): void
    {
        Notification::fake();
        $this->user->settingsOrDefault()->forceFill(['recurring_reminders' => true])->save();
        $id = $this->rule(['starts_on' => '2026-09-18', 'mode' => 'remind', 'remind_days_before' => 2, 'name' => 'Internet'])->assertCreated()->json('data.id');

        $service = app(RecurringService::class);
        $service->process(RecurringTransaction::query()->findOrFail($id));
        $service->process(RecurringTransaction::query()->findOrFail($id));

        Notification::assertSentToTimes($this->user, RecurringPaymentDue::class, 1);
        $this->assertSame(0, Transaction::query()->count());

        // After the date passes the rule simply moves on.
        $this->travelTo(Carbon::parse('2026-09-19 10:00', 'UTC'));
        $service->process(RecurringTransaction::query()->findOrFail($id));
        $this->assertSame('2026-10-18', RecurringTransaction::query()->findOrFail($id)->next_occurrence_on->toDateString());
    }

    public function test_reminders_respect_the_master_switch(): void
    {
        Notification::fake();
        $this->user->settingsOrDefault()->forceFill(['recurring_reminders' => false])->save();

        $this->rule(['starts_on' => '2026-09-17', 'mode' => 'remind'])->assertCreated();

        Notification::assertNothingSent();
    }

    public function test_paused_rules_do_not_generate_and_resume_from_today(): void
    {
        $id = $this->rule(['starts_on' => '2026-09-16', 'paused' => true])->assertCreated()->assertJsonPath('data.paused', true)->json('data.id');
        $this->assertSame(0, Transaction::query()->count());

        $this->travelTo(Carbon::parse('2026-11-05 09:00', 'UTC'));
        $this->patchJson("/api/v1/recurring/{$id}", ['paused' => false, 'starts_on' => '2026-09-16'])
            ->assertOk()
            ->assertJsonPath('data.paused', false)
            ->assertJsonPath('data.next_occurrence_on', '2026-11-16');

        $this->assertSame(0, Transaction::query()->count());
    }

    public function test_transfer_rule_and_validation(): void
    {
        $savings = $this->account($this->user, ['currency' => 'ILS']);
        $usd = $this->account($this->user, ['currency' => 'USD']);

        $this->rule(['type' => 'transfer', 'category_id' => null, 'transfer_account_id' => $savings->id, 'starts_on' => '2026-09-16', 'amount' => '500'])
            ->assertCreated();
        $this->assertSame(500_00, $savings->refresh()->balance);

        $this->rule(['type' => 'transfer', 'category_id' => null, 'transfer_account_id' => $usd->id])
            ->assertUnprocessable()->assertJsonValidationErrors('transfer_amount');
        $this->rule(['category_id' => $this->salary->id])->assertUnprocessable()->assertJsonValidationErrors('category_id');
        $this->rule(['frequency' => 'hourly', 'interval' => 0, 'amount' => '1.234'])
            ->assertUnprocessable()->assertJsonValidationErrors(['frequency', 'interval']);
        $this->rule(['ends_on' => '2026-01-01'])->assertUnprocessable()->assertJsonValidationErrors('ends_on');
    }

    public function test_ownership_upcoming_and_delete_keeps_history(): void
    {
        $id = $this->rule(['starts_on' => '2026-09-01'])->json('data.id');
        $this->rule(['starts_on' => '2026-09-25', 'name' => 'Gym', 'amount' => '150']);

        $this->getJson('/api/v1/recurring/upcoming?days=14')->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.name', 'Gym');
        $this->getJson('/api/v1/dashboard')->assertJsonCount(1, 'data.upcoming_recurring');

        $this->deleteJson("/api/v1/recurring/{$id}")->assertNoContent();
        $this->assertSame(1, Transaction::query()->count());

        $this->signIn();
        $this->getJson('/api/v1/recurring')->assertJsonCount(0, 'data');
    }
}
