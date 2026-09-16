<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Services\TransactionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CategoryTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_create_and_filter_categories(): void
    {
        $user = $this->signIn();
        $this->category($user, 'income', ['name' => 'Freelance']);

        $this->postJson('/api/v1/categories', ['name' => 'Coffee', 'type' => 'expense', 'icon' => 'local_cafe', 'color' => '#7C3AED'])
            ->assertCreated()
            ->assertJsonPath('data.name', 'Coffee')
            ->assertJsonPath('data.default_key', null);

        $this->getJson('/api/v1/categories?type=expense')->assertOk()->assertJsonCount(1, 'data');
        $this->getJson('/api/v1/categories')->assertOk()->assertJsonCount(2, 'data');
    }

    public function test_subcategory_must_match_parent_type_and_ownership(): void
    {
        $user = $this->signIn();
        $income = $this->category($user, 'income');
        $foreign = Category::factory()->create();
        $expense = $this->category($user, 'expense');

        $this->postJson('/api/v1/categories', ['name' => 'Sub', 'type' => 'expense', 'parent_id' => $income->id])
            ->assertUnprocessable()->assertJsonValidationErrors('parent_id');
        $this->postJson('/api/v1/categories', ['name' => 'Sub', 'type' => 'expense', 'parent_id' => $foreign->id])
            ->assertUnprocessable()->assertJsonValidationErrors('parent_id');
        $this->postJson('/api/v1/categories', ['name' => 'Sub', 'type' => 'expense', 'parent_id' => $expense->id])
            ->assertCreated()->assertJsonPath('data.parent_id', $expense->id);
    }

    public function test_only_two_levels_of_nesting_are_allowed(): void
    {
        $user = $this->signIn();
        $parent = $this->category($user);
        $child = $this->category($user, 'expense', ['parent_id' => $parent->id]);

        $this->postJson('/api/v1/categories', ['name' => 'Grandchild', 'type' => 'expense', 'parent_id' => $child->id])
            ->assertUnprocessable()->assertJsonValidationErrors('parent_id');

        $other = $this->category($user);
        $this->patchJson("/api/v1/categories/{$parent->id}", ['parent_id' => $other->id])
            ->assertUnprocessable()->assertJsonValidationErrors('parent_id');
    }

    public function test_type_cannot_be_changed_after_creation(): void
    {
        $user = $this->signIn();
        $category = $this->category($user);

        $this->patchJson("/api/v1/categories/{$category->id}", ['type' => 'income'])
            ->assertUnprocessable()->assertJsonValidationErrors('type');
    }

    public function test_renaming_a_default_category_stops_auto_localization(): void
    {
        $user = $this->signIn();
        $category = $this->category($user);
        $category->forceFill(['default_key' => 'food'])->save();

        $this->patchJson("/api/v1/categories/{$category->id}", ['color' => '#000000'])->assertJsonPath('data.default_key', 'food');
        $this->patchJson("/api/v1/categories/{$category->id}", ['name' => 'Eating out'])->assertJsonPath('data.default_key', null);
    }

    public function test_foreign_categories_are_not_found(): void
    {
        $this->signIn();
        $foreign = Category::factory()->create();

        $this->getJson("/api/v1/categories/{$foreign->id}")->assertNotFound();
        $this->deleteJson("/api/v1/categories/{$foreign->id}")->assertNotFound();
    }

    public function test_deleting_a_category_moves_transactions_to_replacement_and_promotes_children(): void
    {
        $user = $this->signIn();
        $account = $this->account($user, ['opening_balance' => 100_00]);
        $old = $this->category($user);
        $child = $this->category($user, 'expense', ['parent_id' => $old->id]);
        $replacement = $this->category($user);
        $incomeCategory = $this->category($user, 'income');

        $transaction = app(TransactionService::class)->create($user, [
            'type' => 'expense', 'account_id' => $account->id, 'category_id' => $old->id, 'amount' => 500, 'occurred_at' => now(),
        ]);

        $this->deleteJson("/api/v1/categories/{$old->id}", ['replacement_id' => $incomeCategory->id])
            ->assertUnprocessable()->assertJsonValidationErrors('replacement_id');

        $this->deleteJson("/api/v1/categories/{$old->id}", ['replacement_id' => $replacement->id])->assertNoContent();

        $this->assertSoftDeleted($old);
        $this->assertSame($replacement->id, $transaction->refresh()->category_id);
        $this->assertNull($child->refresh()->parent_id);
        $this->assertSame(95_00, $account->refresh()->balance);
    }
}
