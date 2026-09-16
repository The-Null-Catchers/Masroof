<?php

namespace Tests;

use App\Models\Account;
use App\Models\Category;
use App\Models\User;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;
use Laravel\Sanctum\Sanctum;

abstract class TestCase extends BaseTestCase
{
    protected function signIn(?User $user = null): User
    {
        $user ??= User::factory()->create();
        Sanctum::actingAs($user);

        return $user;
    }

    /** @param  array<string, mixed>  $attributes */
    protected function account(User $user, array $attributes = []): Account
    {
        $opening = $attributes['opening_balance'] ?? 0;

        return Account::factory()->for($user)->create($attributes + ['balance' => $opening]);
    }

    /** @param  array<string, mixed>  $attributes */
    protected function category(User $user, string $type = 'expense', array $attributes = []): Category
    {
        return Category::factory()->for($user)->create($attributes + ['type' => $type]);
    }
}
