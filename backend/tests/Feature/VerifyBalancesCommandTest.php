<?php

namespace Tests\Feature;

use App\Services\TransactionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class VerifyBalancesCommandTest extends TestCase
{
    use RefreshDatabase;

    public function test_it_detects_and_fixes_drift(): void
    {
        $user = $this->signIn();
        $account = $this->account($user, ['opening_balance' => 100_00]);
        $category = $this->category($user);
        app(TransactionService::class)->create($user, ['type' => 'expense', 'account_id' => $account->id, 'category_id' => $category->id, 'amount' => 10_00, 'occurred_at' => now()]);

        $this->artisan('masroof:verify-balances')->assertSuccessful();

        $account->forceFill(['balance' => 1])->save();
        $this->artisan('masroof:verify-balances')->assertFailed();
        $this->artisan('masroof:verify-balances --fix')->assertSuccessful();

        $this->assertSame(90_00, $account->refresh()->balance);
    }
}
