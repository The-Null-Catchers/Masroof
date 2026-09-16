<?php

namespace Tests\Feature;

use App\Models\Account;
use App\Models\Category;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Testing\TestResponse;
use Tests\TestCase;

class TransactionExtrasTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    private Account $wallet;

    private Category $food;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = $this->signIn();
        $this->wallet = $this->account($this->user, ['currency' => 'ILS', 'opening_balance' => 1_000_00]);
        $this->food = $this->category($this->user, 'expense', ['name' => 'Restaurants']);
    }

    /** @param  array<string, mixed>  $overrides */
    private function expense(array $overrides = []): TestResponse
    {
        return $this->postJson('/api/v1/transactions', $overrides + [
            'type' => 'expense', 'account_id' => $this->wallet->id, 'category_id' => $this->food->id,
            'amount' => '42.00', 'occurred_at' => '2026-09-10T12:00:00Z', 'merchant' => 'Zaytouna Cafe',
        ]);
    }

    public function test_merchant_payment_method_location_and_tags_are_stored(): void
    {
        $this->expense([
            'payment_method' => 'card', 'location_name' => 'Ramallah', 'latitude' => 31.9038, 'longitude' => 35.2034,
            'tags' => ['Work', ' work ', 'Lunch'],
        ])->assertCreated()
            ->assertJsonPath('data.merchant', 'Zaytouna Cafe')
            ->assertJsonPath('data.payment_method', 'card')
            ->assertJsonPath('data.location.name', 'Ramallah')
            ->assertJsonPath('data.location.latitude', 31.9038)
            ->assertJsonCount(2, 'data.tags');

        $this->assertSame(2, $this->user->tags()->count());
    }

    public function test_invalid_extras_are_rejected(): void
    {
        $this->expense(['payment_method' => 'bitcoin', 'latitude' => 120, 'tags' => array_fill(0, 11, 'x')])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['payment_method', 'latitude', 'longitude', 'tags']);
    }

    public function test_updating_tags_advances_updated_at_for_sync(): void
    {
        $id = $this->expense(['tags' => ['a']])->json('data.id');
        $before = Transaction::query()->findOrFail($id)->updated_at;
        $this->travel(5)->seconds();

        $this->patchJson("/api/v1/transactions/{$id}", ['tags' => ['a', 'b']])->assertOk()->assertJsonCount(2, 'data.tags');

        $this->assertTrue(Transaction::query()->findOrFail($id)->updated_at->gt($before));
    }

    public function test_duplicate_copies_the_transaction_with_tags_and_updates_balance(): void
    {
        $id = $this->expense(['tags' => ['coffee'], 'note' => 'weekly'])->json('data.id');

        $copy = $this->postJson("/api/v1/transactions/{$id}/duplicate", ['occurred_at' => '2026-09-17T08:00:00Z'])
            ->assertCreated()
            ->assertJsonPath('data.merchant', 'Zaytouna Cafe')
            ->assertJsonPath('data.note', 'weekly')
            ->assertJsonPath('data.tags.0.name', 'coffee')
            ->assertJsonPath('data.occurred_at', '2026-09-17T08:00:00+00:00')
            ->json('data.id');

        $this->assertNotSame($id, $copy);
        $this->assertSame(916_00, $this->wallet->refresh()->balance);
    }

    public function test_cannot_duplicate_foreign_transactions(): void
    {
        $other = User::factory()->create();
        $tx = Transaction::factory()->for($other)->create([
            'account_id' => $this->account($other)->id, 'category_id' => $this->category($other)->id, 'currency' => 'SAR',
        ]);

        $this->postJson("/api/v1/transactions/{$tx->id}/duplicate")->assertNotFound();
    }

    public function test_filters_by_amount_range_tags_merchant_and_payment_method(): void
    {
        $jod = $this->account($this->user, ['currency' => 'JOD']);
        $this->expense(['amount' => '10', 'merchant' => 'Bravo', 'payment_method' => 'cash']);
        $tagged = $this->expense(['amount' => '55.5', 'tags' => ['groceries']])->json('data.tags.0.id');
        $this->expense(['amount' => '120', 'merchant' => 'Rimal Books']);
        $this->expense(['account_id' => $jod->id, 'amount' => '50.125']);

        $this->getJson('/api/v1/transactions?min_amount=50&max_amount=100')->assertJsonCount(2, 'data');
        $this->getJson('/api/v1/transactions?min_amount=50.2')->assertJsonCount(2, 'data');
        $this->getJson("/api/v1/transactions?tags[]={$tagged}")->assertJsonCount(1, 'data');
        $this->getJson('/api/v1/transactions?merchant=bravo')->assertJsonCount(1, 'data');
        $this->getJson('/api/v1/transactions?payment_method=cash')->assertJsonCount(1, 'data');
    }

    public function test_search_matches_category_tags_and_exact_amounts(): void
    {
        $this->expense(['merchant' => null, 'amount' => '19.90']);
        $this->expense(['merchant' => 'Other', 'amount' => '5', 'tags' => ['Birthday']]);
        $this->expense(['merchant' => 'Other', 'amount' => '7', 'note' => 'nothing']);

        $this->getJson('/api/v1/transactions?search=restaur')->assertJsonCount(3, 'data');
        $this->getJson('/api/v1/transactions?search=birth')->assertJsonCount(1, 'data');
        $this->getJson('/api/v1/transactions?search=19.9')->assertJsonCount(1, 'data');
    }

    public function test_tags_crud_is_scoped_and_case_insensitive(): void
    {
        $id = $this->postJson('/api/v1/tags', ['name' => 'Travel'])->assertCreated()->json('data.id');
        $this->postJson('/api/v1/tags', ['name' => 'travel'])->assertUnprocessable()->assertJsonValidationErrors('name');
        $this->patchJson("/api/v1/tags/{$id}", ['name' => 'Trips', 'color' => '#0F7A68'])->assertOk()->assertJsonPath('data.name', 'Trips');
        $this->getJson('/api/v1/tags')->assertJsonPath('data.0.transactions_count', 0);

        $foreign = User::factory()->create()->tags()->create(['name' => 'secret']);
        $this->patchJson("/api/v1/tags/{$foreign->id}", ['name' => 'mine'])->assertNotFound();
        $this->deleteJson("/api/v1/tags/{$id}")->assertNoContent();
    }

    public function test_account_notes(): void
    {
        $this->patchJson("/api/v1/accounts/{$this->wallet->id}", ['notes' => 'Salary lands here'])
            ->assertOk()->assertJsonPath('data.notes', 'Salary lands here');
    }
}
