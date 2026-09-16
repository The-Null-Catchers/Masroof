<?php

namespace App\Models;

use App\Enums\TransactionType;
use Database\Factories\TransactionFactory;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Carbon;

/**
 * Writes must go through App\Services\TransactionService so balances stay consistent.
 *
 * @property string $id
 * @property string $user_id
 * @property string $account_id
 * @property string|null $category_id
 * @property TransactionType $type
 * @property int $amount
 * @property string $currency
 * @property string|null $transfer_account_id
 * @property int|null $transfer_amount
 * @property Carbon $occurred_at
 * @property string|null $payee
 * @property string|null $note
 * @property Carbon|null $created_at
 * @property Carbon|null $updated_at
 * @property Carbon|null $deleted_at
 */
class Transaction extends Model
{
    /** @use HasFactory<TransactionFactory> */
    use HasFactory, HasUlids, SoftDeletes;

    protected $guarded = ['id', 'user_id', 'created_at', 'updated_at', 'deleted_at'];

    protected $attributes = [
        'category_id' => null,
        'transfer_account_id' => null,
        'transfer_amount' => null,
        'payee' => null,
        'note' => null,
    ];

    protected function casts(): array
    {
        return [
            'type' => TransactionType::class,
            'amount' => 'integer',
            'transfer_amount' => 'integer',
            'occurred_at' => 'datetime',
        ];
    }

    /** @return BelongsTo<User, $this> */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /** @return BelongsTo<Account, $this> */
    public function account(): BelongsTo
    {
        return $this->belongsTo(Account::class)->withTrashed();
    }

    /** @return BelongsTo<Account, $this> */
    public function transferAccount(): BelongsTo
    {
        return $this->belongsTo(Account::class, 'transfer_account_id')->withTrashed();
    }

    /** @return BelongsTo<Category, $this> */
    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class)->withTrashed();
    }

    /**
     * Signed balance effect of this transaction, keyed by account id.
     *
     * @return array<string, int>
     */
    public function balanceEffects(): array
    {
        return match ($this->type) {
            TransactionType::Income => [$this->account_id => $this->amount],
            TransactionType::Expense => [$this->account_id => -$this->amount],
            TransactionType::Transfer => [
                $this->account_id => -$this->amount,
                (string) $this->transfer_account_id => (int) $this->transfer_amount,
            ],
        };
    }
}
