<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
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
 * @property string $kind
 * @property string $currency
 * @property int $target_amount
 * @property int $current_amount
 * @property Carbon|null $target_date
 * @property string|null $account_id
 * @property string|null $icon
 * @property string|null $color
 * @property string|null $notes
 * @property Carbon|null $achieved_at
 * @property Carbon|null $archived_at
 * @property Carbon|null $created_at
 * @property Carbon|null $updated_at
 */
#[Fillable(['name', 'kind', 'currency', 'target_amount', 'target_date', 'account_id', 'icon', 'color', 'notes'])]
class Goal extends Model
{
    use HasUlids, SoftDeletes;

    public const KINDS = ['emergency_fund', 'laptop', 'car', 'travel', 'wedding', 'home', 'custom'];

    protected $attributes = [
        'kind' => 'custom',
        'current_amount' => 0,
        'target_date' => null,
        'account_id' => null,
        'icon' => null,
        'color' => null,
        'notes' => null,
        'achieved_at' => null,
        'archived_at' => null,
    ];

    protected function casts(): array
    {
        return [
            'target_amount' => 'integer',
            'current_amount' => 'integer',
            'target_date' => 'date',
            'achieved_at' => 'datetime',
            'archived_at' => 'datetime',
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

    /** @return HasMany<GoalTransaction, $this> */
    public function entries(): HasMany
    {
        return $this->hasMany(GoalTransaction::class);
    }
}
