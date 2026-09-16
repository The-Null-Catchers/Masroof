<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class GoalTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->travelTo(Carbon::parse('2026-09-16 09:00', 'UTC'));
        $this->user = $this->signIn();
    }

    private function goal(array $overrides = []): string
    {
        return $this->postJson('/api/v1/goals', $overrides + [
            'name' => 'Emergency fund', 'kind' => 'emergency_fund', 'currency' => 'ILS',
            'target_amount' => '12000', 'target_date' => '2027-09-15',
        ])->assertCreated()->json('data.id');
    }

    public function test_create_goal_with_initial_progress(): void
    {
        $this->postJson('/api/v1/goals', ['name' => 'Laptop', 'kind' => 'laptop', 'currency' => 'JOD', 'target_amount' => '900.500', 'target_date' => '2027-03-16'])
            ->assertCreated()
            ->assertJsonPath('data.target_amount', '900.500')
            ->assertJsonPath('data.current_amount', '0.000')
            ->assertJsonPath('data.progress.percent', 0)
            // Six months left: 900.500 / 6 = 150.084 (rounded up)
            ->assertJsonPath('data.progress.monthly_needed', '150.084')
            ->assertJsonPath('data.progress.expected_completion_date', null);
    }

    public function test_contributions_withdrawals_and_projection(): void
    {
        $id = $this->goal();

        $this->postJson("/api/v1/goals/{$id}/entries", ['type' => 'contribution', 'amount' => '1000', 'occurred_at' => '2026-07-18T10:00:00Z'])->assertCreated();
        $this->postJson("/api/v1/goals/{$id}/entries", ['type' => 'contribution', 'amount' => '1000', 'occurred_at' => '2026-08-17T10:00:00Z'])->assertCreated();
        $response = $this->postJson("/api/v1/goals/{$id}/entries", ['type' => 'withdrawal', 'amount' => '500', 'occurred_at' => '2026-09-15T10:00:00Z', 'note' => 'Car repair'])
            ->assertCreated()
            ->assertJsonPath('goal.current_amount', '1500.00')
            ->assertJsonPath('goal.progress.remaining', '10500.00')
            ->assertJsonPath('goal.progress.percent', 12.5);

        // ~60 days of history with net 1500 → ~750/month → ~14 months to go.
        $expected = $response->json('goal.progress.expected_completion_date');
        $this->assertNotNull($expected);
        $this->assertTrue(Carbon::parse($expected)->between('2027-10-01', '2027-12-31'), $expected);

        $this->getJson("/api/v1/goals/{$id}/entries")->assertJsonCount(3, 'data')->assertJsonPath('data.0.note', 'Car repair');
    }

    public function test_withdrawal_cannot_exceed_saved_amount(): void
    {
        $id = $this->goal();
        $this->postJson("/api/v1/goals/{$id}/entries", ['type' => 'contribution', 'amount' => '100'])->assertCreated();

        $this->postJson("/api/v1/goals/{$id}/entries", ['type' => 'withdrawal', 'amount' => '100.01'])
            ->assertUnprocessable()->assertJsonValidationErrors('amount');
        $this->postJson("/api/v1/goals/{$id}/entries", ['type' => 'contribution', 'amount' => '1.234'])
            ->assertUnprocessable()->assertJsonValidationErrors('amount');
    }

    public function test_goal_is_achieved_and_reopened(): void
    {
        $id = $this->goal(['target_amount' => '500']);
        $entry = $this->postJson("/api/v1/goals/{$id}/entries", ['type' => 'contribution', 'amount' => '500'])
            ->assertJsonPath('goal.achieved', true)
            ->assertJsonPath('goal.progress.percent', 100)
            ->json('data.id');

        $this->patchJson("/api/v1/goals/{$id}", ['target_amount' => '800'])->assertOk()->assertJsonPath('data.achieved', false);

        $this->deleteJson("/api/v1/goals/{$id}/entries/{$entry}")->assertOk()->assertJsonPath('goal.current_amount', '0.00');
    }

    public function test_cannot_delete_contribution_that_funded_a_withdrawal(): void
    {
        $id = $this->goal();
        $entry = $this->postJson("/api/v1/goals/{$id}/entries", ['type' => 'contribution', 'amount' => '100'])->json('data.id');
        $this->postJson("/api/v1/goals/{$id}/entries", ['type' => 'withdrawal', 'amount' => '80']);

        $this->deleteJson("/api/v1/goals/{$id}/entries/{$entry}")->assertUnprocessable();
    }

    public function test_validation_and_ownership(): void
    {
        $this->postJson('/api/v1/goals', ['name' => '', 'kind' => 'yacht', 'currency' => 'ILS', 'target_amount' => '0'])
            ->assertUnprocessable()->assertJsonValidationErrors(['name', 'kind', 'target_amount']);

        $id = $this->goal();
        $this->patchJson("/api/v1/goals/{$id}", ['currency' => 'USD'])->assertUnprocessable()->assertJsonValidationErrors('currency');

        $this->signIn();
        $this->getJson("/api/v1/goals/{$id}")->assertNotFound();
        $this->postJson("/api/v1/goals/{$id}/entries", ['type' => 'contribution', 'amount' => '1'])->assertNotFound();
    }
}
