<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Carbon;

/**
 * @property string $id
 * @property string $user_id
 * @property string $name
 * @property string $period
 * @property string $currency
 * @property int $amount
 * @property Carbon|null $starts_on
 * @property Carbon|null $ends_on
 * @property array<int, int> $alert_thresholds
 * @property Carbon|null $archived_at
 * @property Carbon|null $created_at
 * @property Carbon|null $updated_at
 */
#[Fillable(['name', 'period', 'currency', 'amount', 'starts_on', 'ends_on', 'alert_thresholds'])]
class Budget extends Model
{
    use HasUlids, SoftDeletes;

    public const DEFAULT_THRESHOLDS = [50, 75, 90, 100];

    protected $attributes = [
        'starts_on' => null,
        'ends_on' => null,
        'archived_at' => null,
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'integer',
            'starts_on' => 'date',
            'ends_on' => 'date',
            'alert_thresholds' => 'array',
            'archived_at' => 'datetime',
        ];
    }

    /** @return BelongsTo<User, $this> */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /** @return BelongsToMany<Category, $this> */
    public function categories(): BelongsToMany
    {
        return $this->belongsToMany(Category::class, 'budget_categories');
    }
}
