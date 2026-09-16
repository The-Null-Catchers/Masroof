<?php

namespace App\Console\Commands;

use App\Models\Account;
use App\Services\TransactionService;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Log;

#[Signature('masroof:verify-balances {--fix : Correct any drifted balances}')]
#[Description('Compare every stored account balance with its transaction history')]
class VerifyBalances extends Command
{
    public function handle(TransactionService $service): int
    {
        $drifted = 0;

        Account::query()->withTrashed()->lazyById(200)->each(function (Account $account) use ($service, &$drifted) {
            $stored = $account->balance;
            $expected = $this->option('fix')
                ? $service->recalculate($account)
                : $this->expectedBalance($account);

            if ($stored !== $expected) {
                $drifted++;
                Log::warning('Account balance drift detected', ['account_id' => $account->id, 'stored' => $stored, 'expected' => $expected]);
                $this->warn("{$account->id}: stored {$stored}, expected {$expected}");
            }
        });

        $this->info($drifted === 0 ? 'All balances are consistent.' : "{$drifted} account(s) drifted.");

        return $drifted === 0 || $this->option('fix') ? self::SUCCESS : self::FAILURE;
    }

    private function expectedBalance(Account $account): int
    {
        $income = (int) $account->transactions()->where('type', 'income')->sum('amount');
        $outgoing = (int) $account->transactions()->whereIn('type', ['expense', 'transfer'])->sum('amount');
        $incoming = (int) $account->incomingTransfers()->where('type', 'transfer')->sum('transfer_amount');

        return $account->opening_balance + $income - $outgoing + $incoming;
    }
}
