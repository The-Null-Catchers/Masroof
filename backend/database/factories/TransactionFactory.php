<?php

namespace Database\Factories;

use App\Enums\TransactionType;
use App\Models\Transaction;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * Raw rows for read-only tests. Tests that depend on balances must create
 * transactions through App\Services\TransactionService instead.
 *
 * @extends Factory<Transaction>
 */
class TransactionFactory extends Factory
{
    public function definition(): array
    {
        return [
            'type' => TransactionType::Expense,
            'amount' => fake()->numberBetween(100, 50_000),
            'currency' => 'SAR',
            'occurred_at' => fake()->dateTimeBetween('-60 days'),
            'payee' => fake()->company(),
        ];
    }
}
