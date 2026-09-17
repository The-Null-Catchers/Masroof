<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * @property int $id
 * @property string|null $admin_id
 * @property string $action
 * @property string|null $target_user_id
 * @property array<string, mixed>|null $meta
 * @property Carbon $created_at
 */
class AdminAuditLog extends Model
{
    public const UPDATED_AT = null;

    protected $guarded = ['id'];

    protected function casts(): array
    {
        return ['meta' => 'array', 'created_at' => 'datetime'];
    }

    /** @param  array<string, mixed>|null  $meta */
    public static function record(User $admin, string $action, ?User $target = null, ?array $meta = null): self
    {
        return self::query()->create([
            'admin_id' => $admin->id,
            'action' => $action,
            'target_user_id' => $target?->id,
            'meta' => $meta,
        ]);
    }

    /** @return BelongsTo<User, $this> */
    public function admin(): BelongsTo
    {
        return $this->belongsTo(User::class, 'admin_id');
    }

    /** @return BelongsTo<User, $this> */
    public function target(): BelongsTo
    {
        return $this->belongsTo(User::class, 'target_user_id');
    }
}
