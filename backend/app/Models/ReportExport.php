<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * @property string $id
 * @property string $user_id
 * @property string $type
 * @property string $format
 * @property array<string, mixed> $parameters
 * @property string $status
 * @property string|null $file_path
 * @property string|null $file_name
 * @property int|null $size
 * @property string|null $error
 * @property Carbon|null $completed_at
 * @property Carbon|null $expires_at
 * @property Carbon|null $created_at
 */
class ReportExport extends Model
{
    use HasUlids;

    public const FORMATS = [
        'transactions' => ['csv', 'xlsx', 'pdf'],
        'monthly' => ['pdf', 'xlsx'],
        'budgets' => ['pdf', 'xlsx', 'csv'],
        'income_expense' => ['pdf', 'xlsx', 'csv'],
        'categories' => ['pdf', 'xlsx', 'csv'],
    ];

    protected $guarded = ['id', 'user_id'];

    protected $attributes = [
        'status' => 'pending',
        'file_path' => null,
        'file_name' => null,
        'size' => null,
        'error' => null,
        'completed_at' => null,
        'expires_at' => null,
    ];

    protected function casts(): array
    {
        return [
            'parameters' => 'array',
            'size' => 'integer',
            'completed_at' => 'datetime',
            'expires_at' => 'datetime',
        ];
    }

    /** @return BelongsTo<User, $this> */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
