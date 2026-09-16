<?php

namespace App\Services;

use App\Enums\TransactionType;
use App\Models\Account;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Support\Facades\DB;

/**
 * The only write path for transactions. Every change applies its balance
 * effects atomically while holding row locks on the affected accounts, so
 * account balances can never drift from their transaction history.
 */
class TransactionService
{
    /**
     * @param  array<string, mixed>  $data  Validated attributes with amounts already in minor units.
     */
    public function create(User $user, array $data): Transaction
    {
        return DB::transaction(function () use ($user, $data) {
            $transaction = new Transaction($this->normalize($data));
            if (isset($data['id'])) {
                $transaction->id = $data['id'];
            }
            $transaction->user_id = $user->id;

            $this->applyEffects($transaction->balanceEffects(), 1);
            $transaction->save();

            return $transaction;
        });
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public function update(Transaction $transaction, array $data): Transaction
    {
        return DB::transaction(function () use ($transaction, $data) {
            $transaction = Transaction::query()->lockForUpdate()->findOrFail($transaction->id);
            $before = $transaction->balanceEffects();

            $transaction->fill($this->normalize(array_merge([
                'type' => $transaction->type->value,
                'account_id' => $transaction->account_id,
                'transfer_account_id' => $transaction->transfer_account_id,
                'transfer_amount' => $transaction->transfer_amount,
                'category_id' => $transaction->category_id,
                'amount' => $transaction->amount,
            ], $data)));

            $after = $transaction->balanceEffects();
            $this->applyEffects($this->diff($before, $after), 1);
            $transaction->save();

            return $transaction;
        });
    }

    public function delete(Transaction $transaction): void
    {
        DB::transaction(function () use ($transaction) {
            $transaction = Transaction::query()->lockForUpdate()->findOrFail($transaction->id);
            $this->applyEffects($transaction->balanceEffects(), -1);
            $transaction->delete();
        });
    }

    /**
     * Rebuild an account balance from its opening balance and full history.
     */
    public function recalculate(Account $account): int
    {
        return DB::transaction(function () use ($account) {
            $account = Account::query()->lockForUpdate()->findOrFail($account->id);

            $sums = Transaction::query()
                ->where('account_id', $account->id)
                ->selectRaw("
                    COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0) AS income,
                    COALESCE(SUM(CASE WHEN type IN ('expense', 'transfer') THEN amount ELSE 0 END), 0) AS outgoing
                ")
                ->first();

            $incoming = (int) Transaction::query()
                ->where('transfer_account_id', $account->id)
                ->where('type', TransactionType::Transfer->value)
                ->sum('transfer_amount');

            $balance = $account->opening_balance + (int) $sums?->getAttribute('income') - (int) $sums?->getAttribute('outgoing') + $incoming;

            if ($balance !== $account->balance) {
                $account->forceFill(['balance' => $balance])->save();
            }

            return $balance;
        });
    }

    /**
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    private function normalize(array $data): array
    {
        $type = $data['type'] instanceof TransactionType ? $data['type'] : TransactionType::from($data['type']);
        $account = Account::query()->findOrFail($data['account_id']);

        $normalized = array_intersect_key($data, array_flip([
            'account_id', 'category_id', 'amount', 'occurred_at', 'payee', 'note',
            'transfer_account_id', 'transfer_amount',
        ]));
        $normalized['type'] = $type;
        $normalized['currency'] = $account->currency;

        if ($type === TransactionType::Transfer) {
            $destination = Account::query()->findOrFail($data['transfer_account_id']);
            $normalized['category_id'] = null;
            $normalized['transfer_amount'] = $destination->currency === $account->currency
                ? (int) $data['amount']
                : (int) $data['transfer_amount'];
        } else {
            $normalized['transfer_account_id'] = null;
            $normalized['transfer_amount'] = null;
        }

        return $normalized;
    }

    /**
     * @param  array<string, int>  $before
     * @param  array<string, int>  $after
     * @return array<string, int>
     */
    private function diff(array $before, array $after): array
    {
        $delta = [];
        foreach ($after as $accountId => $amount) {
            $delta[$accountId] = ($delta[$accountId] ?? 0) + $amount;
        }
        foreach ($before as $accountId => $amount) {
            $delta[$accountId] = ($delta[$accountId] ?? 0) - $amount;
        }

        return array_filter($delta, fn (int $amount) => $amount !== 0);
    }

    /**
     * @param  array<string, int>  $effects
     */
    private function applyEffects(array $effects, int $direction): void
    {
        // Lock in a stable order to avoid deadlocks between concurrent transfers.
        ksort($effects);

        foreach ($effects as $accountId => $amount) {
            $account = Account::withTrashed()->lockForUpdate()->findOrFail($accountId);
            $account->forceFill(['balance' => $account->balance + ($amount * $direction)])->save();
        }
    }
}
