<?php

namespace Database\Seeders\Demo;

use App\Models\Account;
use App\Models\Budget;
use App\Models\User;
use App\Services\DefaultCategories;
use App\Services\GoalService;
use App\Services\TransactionService;
use Carbon\CarbonImmutable;
use Illuminate\Database\Seeder;
use Illuminate\Support\Collection;

/**
 * Realistic, deterministic demo data: three months of activity for a user in
 * Ramallah with ILS, USD and JOD accounts, budgets and savings goals.
 *
 * Login: demo@masroof.app / password1
 */
class DemoUserSeeder extends Seeder
{
    public const EMAIL = 'demo@masroof.app';

    public function __construct(
        private readonly DefaultCategories $defaults,
        private readonly TransactionService $transactions,
        private readonly GoalService $goals,
    ) {}

    public function run(): void
    {
        if (User::query()->where('email', self::EMAIL)->exists()) {
            $this->command?->info('Demo user already exists; skipping.');

            return;
        }

        mt_srand(2026);
        $now = CarbonImmutable::now('Asia/Hebron');

        $user = User::query()->create([
            'name' => 'Layla Haddad', 'email' => self::EMAIL, 'password' => 'password1',
            'locale' => 'ar', 'currency' => 'ILS', 'timezone' => 'Asia/Hebron', 'week_start' => 6,
        ]);
        $user->markEmailAsVerified();
        $this->defaults->provision($user);
        $cat = $user->categories()->pluck('id', 'default_key');

        $bank = $this->account($user, 'Bank of Palestine', 'bank', 'ILS', 6_450_00, '#0F7A68', 'account_balance');
        $cash = $this->account($user, 'Wallet', 'cash', 'ILS', 380_00, '#F5B83D', 'payments');
        $card = $this->account($user, 'Visa card', 'credit_card', 'ILS', 0, '#2563EB', 'credit_card');
        $savings = $this->account($user, 'USD savings', 'savings', 'USD', 3_200_00, '#7C3AED', 'savings');
        $jod = $this->account($user, 'Amman account', 'bank', 'JOD', 410_500, '#DB2777', 'account_balance');

        $user->settingsOrDefault()->forceFill([
            'onboarding_completed_at' => $now->subMonths(3),
            'monthly_income_estimate' => 9_500_00,
            'main_goal' => 'emergency_fund',
            'default_account_id' => $bank->id,
        ])->save();

        $start = $now->subMonthsNoOverflow(2)->startOfMonth();
        for ($month = $start; $month->lte($now); $month = $month->addMonthNoOverflow()) {
            $this->seedMonth($user, $month, $now, $cat, $bank, $cash, $card, $savings, $jod);
        }

        $this->seedBudgets($user, $cat);
        $this->seedGoals($user, $now, $savings);
    }

    private function account(User $user, string $name, string $type, string $currency, int $opening, string $color, string $icon): Account
    {
        $account = $user->accounts()->create(compact('name', 'type', 'currency', 'color', 'icon') + ['opening_balance' => $opening]);
        $account->forceFill(['balance' => $opening])->save();

        return $account;
    }

    /** @param Collection<string, string> $cat */
    private function seedMonth(User $user, CarbonImmutable $month, CarbonImmutable $now, Collection $cat, Account $bank, Account $cash, Account $card, Account $savings, Account $jod): void
    {
        $add = function (string $type, string $category, Account $account, int $amount, int $day, int $hour, ?string $merchant = null, array $extra = []) use ($user, $month, $now, $cat) {
            $when = $month->setDay(min($day, $month->daysInMonth))->setTime($hour, mt_rand(0, 59));
            if ($when->gt($now)) {
                return;
            }
            $this->transactions->create($user, [
                'type' => $type, 'account_id' => $account->id, 'category_id' => $cat[$category] ?? null,
                'amount' => $amount, 'occurred_at' => $when->utc(), 'merchant' => $merchant,
            ] + $extra);
        };

        // Income
        $add('income', 'salary', $bank, 9_200_00, 1, 9, 'Tech company payroll', ['payment_method' => 'bank_transfer']);
        $add('income', 'freelancing', $bank, mt_rand(600, 1400) * 100, 18, 14, 'Upwork', ['tags' => ['freelance']]);

        // Fixed costs
        $add('expense', 'rent', $bank, 2_800_00, 2, 10, 'Landlord', ['payment_method' => 'bank_transfer']);
        $add('expense', 'internet', $bank, 129_00, 5, 11, 'Paltel', ['payment_method' => 'card']);
        $add('expense', 'mobile', $card, 79_00, 6, 12, 'Jawwal', ['payment_method' => 'card']);
        $add('expense', 'bills', $bank, mt_rand(210, 290) * 100, 8, 18, 'Electricity company');
        $add('expense', 'subscriptions', $card, $month->month === $now->month ? 49_90 : 44_90, 12, 20, 'StreamFlix', ['tags' => ['subscription']]);
        $add('expense', 'subscriptions', $card, 19_90, 15, 20, 'Music+', ['tags' => ['subscription']]);

        // Variable spending
        foreach ([3, 7, 10, 14, 17, 21, 24, 28] as $day) {
            $add('expense', 'groceries', mt_rand(0, 3) ? $card : $cash, mt_rand(90, 340) * 100 + mt_rand(0, 99), $day, 18, ['Bravo Supermarket', 'Plaza Mall', 'Al-Shini Market'][mt_rand(0, 2)], ['payment_method' => 'card']);
        }
        foreach ([4, 9, 13, 16, 20, 25, 27] as $day) {
            $add('expense', mt_rand(0, 1) ? 'restaurants' : 'food', mt_rand(0, 2) ? $card : $cash, mt_rand(25, 160) * 100, $day, 13, ['Zaytouna Cafe', 'Falafel Abu Salem', 'Pizza Inn', 'Coffee Lab'][mt_rand(0, 3)], ['tags' => mt_rand(0, 2) ? [] : ['friends']]);
        }
        foreach ([2, 11, 19, 26] as $day) {
            $add('expense', 'fuel', $card, mt_rand(180, 260) * 100, $day, 8, 'Petrol station', ['payment_method' => 'card']);
        }
        foreach ([6, 15, 23] as $day) {
            $add('expense', 'transportation', $cash, mt_rand(12, 40) * 100, $day, 7, 'Taxi', ['payment_method' => 'cash']);
        }
        $add('expense', 'shopping', $card, mt_rand(150, 600) * 100, 22, 17, ['Zara', 'IKEA', 'Local boutique'][mt_rand(0, 2)]);
        $add('expense', 'entertainment', $card, mt_rand(60, 180) * 100, 16, 21, 'Cinema City', ['tags' => ['friends']]);
        $add('expense', 'healthcare', $cash, mt_rand(80, 220) * 100, 13, 10, 'Pharmacy');
        $add('expense', 'family', $cash, mt_rand(200, 500) * 100, 20, 19, null, ['note' => 'Help for parents']);
        $add('expense', 'education', $jod, mt_rand(30, 60) * 1000, 9, 15, 'Online course');

        // Transfers never count as income or expense
        $this->transfer($user, $month, $now, $bank, $cash, 600_00, 600_00, 3);
        $this->transfer($user, $month, $now, $bank, $card, 2_400_00, 2_400_00, 27);
        $this->transfer($user, $month, $now, $bank, $savings, 1_100_00, 300_00, 5);
    }

    private function transfer(User $user, CarbonImmutable $month, CarbonImmutable $now, Account $from, Account $to, int $amount, int $received, int $day): void
    {
        $when = $month->setDay($day)->setTime(9, 30);
        if ($when->gt($now)) {
            return;
        }
        $this->transactions->create($user, [
            'type' => 'transfer', 'account_id' => $from->id, 'transfer_account_id' => $to->id,
            'amount' => $amount, 'transfer_amount' => $received, 'occurred_at' => $when->utc(),
        ]);
    }

    /** @param Collection<string, string> $cat */
    private function seedBudgets(User $user, Collection $cat): void
    {
        $budgets = [
            ['Monthly spending', 'monthly', 7_500_00, []],
            ['Groceries', 'monthly', 1_800_00, ['groceries']],
            ['Eating out', 'monthly', 600_00, ['restaurants', 'food']],
            ['Transport & fuel', 'monthly', 1_000_00, ['transportation', 'fuel']],
            ['Weekly pocket money', 'weekly', 350_00, ['food', 'entertainment']],
        ];
        foreach ($budgets as [$name, $period, $amount, $keys]) {
            $budget = $user->budgets()->create(['name' => $name, 'period' => $period, 'currency' => 'ILS', 'amount' => $amount, 'alert_thresholds' => Budget::DEFAULT_THRESHOLDS]);
            $budget->categories()->sync(array_map(fn ($key) => $cat[$key], $keys));
        }
    }

    private function seedGoals(User $user, CarbonImmutable $now, Account $savings): void
    {
        $emergency = $user->goals()->create(['name' => 'Emergency fund', 'kind' => 'emergency_fund', 'currency' => 'USD', 'target_amount' => 10_000_00, 'target_date' => $now->addMonths(14)->toDateString(), 'account_id' => $savings->id, 'icon' => 'savings', 'color' => '#0F7A68']);
        $laptop = $user->goals()->create(['name' => 'New laptop', 'kind' => 'laptop', 'currency' => 'ILS', 'target_amount' => 6_500_00, 'target_date' => $now->addMonths(4)->toDateString(), 'icon' => 'laptop', 'color' => '#2563EB']);
        $travel = $user->goals()->create(['name' => 'Trip to Istanbul', 'kind' => 'travel', 'currency' => 'ILS', 'target_amount' => 5_000_00, 'target_date' => $now->addMonths(9)->toDateString(), 'icon' => 'flight', 'color' => '#F97316']);

        foreach ([3, 2, 1] as $ago) {
            $this->goals->addEntry($emergency, 'contribution', 300_00, $now->subMonths($ago)->setDay(5)->utc());
            $this->goals->addEntry($laptop, 'contribution', 900_00, $now->subMonths($ago)->setDay(2)->utc());
            $this->goals->addEntry($travel, 'contribution', 350_00, $now->subMonths($ago)->setDay(10)->utc());
        }
        $this->goals->addEntry($emergency, 'withdrawal', 150_00, $now->subMonth()->setDay(20)->utc(), 'Car repair');
        $this->goals->addEntry($laptop, 'contribution', 1_000_00, $now->subDays(3)->utc(), 'Freelance bonus');
    }
}
