<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * A contribution to or withdrawal from a savings goal.
 *
 * @property string $id
 * @property string $goal_id
 * @property string $type
 * @property int $amount
 * @property Carbon $occurred_at
 * @property string|null $note
 */
class GoalTransaction extends Model
{
    use HasUlids;

    protected $guarded = ['id', 'goal_id'];

    protected $attributes = ['note' => null];

    protected function casts(): array
    {
        return ['amount' => 'integer', 'occurred_at' => 'datetime'];
    }

    /** @return BelongsTo<Goal, $this> */
    public function goal(): BelongsTo
    {
        return $this->belongsTo(Goal::class);
    }

    public function signedAmount(): int
    {
        return $this->type === 'withdrawal' ? -$this->amount : $this->amount;
    }
}
