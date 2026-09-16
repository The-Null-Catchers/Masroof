<?php

namespace Database\Seeders;

use App\Enums\TransactionType;
use App\Models\User;
use App\Services\DefaultCategories;
use App\Services\TransactionService;
use Illuminate\Database\Seeder;

/**
 * Local demo data. Never run in production.
 * Demo login: demo@masroof.app / password1
 */
class DatabaseSeeder extends Seeder
{
    public function run(DefaultCategories $defaults, TransactionService $transactions): void
    {
        $user = User::query()->firstOrCreate(
            ['email' => 'demo@masroof.app'],
            ['name' => 'Demo User', 'password' => 'password1', 'locale' => 'ar', 'currency' => 'ILS'],
        );

        if ($user->accounts()->exists()) {
            return;
        }

        $defaults->provision($user);

        $bank = $user->accounts()->create(['name' => 'Main bank', 'type' => 'bank', 'currency' => 'ILS', 'opening_balance' => 1_250_000, 'color' => '#0F7A68', 'icon' => 'account_balance']);
        $bank->forceFill(['balance' => $bank->opening_balance])->save();
        $cash = $user->accounts()->create(['name' => 'Cash', 'type' => 'cash', 'currency' => 'ILS', 'opening_balance' => 50_000, 'color' => '#F5B83D', 'icon' => 'payments']);
        $cash->forceFill(['balance' => $cash->opening_balance])->save();

        $categories = $user->categories()->pluck('id', 'default_key');

        $transactions->create($user, [
            'type' => TransactionType::Income, 'account_id' => $bank->id, 'category_id' => $categories['salary'],
            'amount' => 1_500_000, 'occurred_at' => now()->startOfMonth()->addDays(1), 'merchant' => 'Employer',
        ]);

        foreach (range(1, 40) as $i) {
            $transactions->create($user, [
                'type' => TransactionType::Expense,
                'account_id' => $i % 3 === 0 ? $cash->id : $bank->id,
                'category_id' => $categories[fake()->randomElement(['food', 'groceries', 'transportation', 'bills', 'shopping', 'entertainment'])],
                'amount' => fake()->numberBetween(1_500, 45_000),
                'occurred_at' => now()->subDays(fake()->numberBetween(0, 45))->setTime(fake()->numberBetween(8, 22), fake()->numberBetween(0, 59)),
                'merchant' => fake()->company(),
            ]);
        }

        $transactions->create($user, [
            'type' => TransactionType::Transfer, 'account_id' => $bank->id, 'transfer_account_id' => $cash->id,
            'amount' => 100_000, 'occurred_at' => now()->subDays(3), 'note' => 'ATM withdrawal',
        ]);
    }
}
