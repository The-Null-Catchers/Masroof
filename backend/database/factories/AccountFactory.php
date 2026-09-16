<?php

namespace Database\Factories;

use App\Enums\AccountType;
use App\Models\Account;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Account>
 */
class AccountFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'name' => fake()->randomElement(['Wallet', 'Main bank', 'Savings', 'Card']),
            'type' => fake()->randomElement(AccountType::cases()),
            'currency' => 'SAR',
            'opening_balance' => 0,
            'balance' => 0,
        ];
    }

    public function withBalance(int $minor): static
    {
        return $this->state(fn () => ['opening_balance' => $minor, 'balance' => $minor]);
    }

    public function currency(string $currency): static
    {
        return $this->state(fn () => ['currency' => $currency]);
    }

    public function archived(): static
    {
        return $this->afterMaking(fn (Account $account) => $account->archived_at = now());
    }
}
