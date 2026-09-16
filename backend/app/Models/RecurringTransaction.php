<?php

namespace App\Models;

use App\Enums\TransactionType;
use Carbon\CarbonInterface;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Carbon;

/**
 * @property string $id
 * @property string $user_id
 * @property string $name
 * @property TransactionType $type
 * @property string $account_id
 * @property string|null $category_id
 * @property string|null $transfer_account_id
 * @property int $amount
 * @property int|null $transfer_amount
 * @property string $currency
 * @property string|null $merchant
 * @property string|null $payment_method
 * @property string|null $note
 * @property string $frequency
 * @property int $interval
 * @property Carbon $starts_on
 * @property Carbon|null $ends_on
 * @property CarbonInterface|null $next_occurrence_on
 * @property string $mode
 * @property int $remind_days_before
 * @property Carbon|null $paused_at
 * @property Carbon|null $created_at
 * @property Carbon|null $updated_at
 */
class RecurringTransaction extends Model
{
    use HasUlids, SoftDeletes;

    public const FREQUENCIES = ['daily', 'weekly', 'monthly', 'yearly'];

    protected $guarded = ['id', 'user_id', 'next_occurrence_on', 'created_at', 'updated_at', 'deleted_at'];

    protected $attributes = [
        'category_id' => null,
        'transfer_account_id' => null,
        'transfer_amount' => null,
        'merchant' => null,
        'payment_method' => null,
        'note' => null,
        'interval' => 1,
        'ends_on' => null,
        'next_occurrence_on' => null,
        'mode' => 'auto',
        'remind_days_before' => 1,
        'paused_at' => null,
    ];

    protected function casts(): array
    {
        return [
            'type' => TransactionType::class,
            'amount' => 'integer',
            'transfer_amount' => 'integer',
            'interval' => 'integer',
            'starts_on' => 'date',
            'ends_on' => 'date',
            'next_occurrence_on' => 'date',
            'remind_days_before' => 'integer',
            'paused_at' => 'datetime',
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

    /** @return BelongsTo<Category, $this> */
    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class)->withTrashed();
    }

    /** @return HasMany<Transaction, $this> */
    public function transactions(): HasMany
    {
        return $this->hasMany(Transaction::class);
    }

    public function isActive(): bool
    {
        return $this->paused_at === null && $this->next_occurrence_on !== null;
    }
}
