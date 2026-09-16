<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;

/**
 * @property string $id
 * @property string $user_id
 * @property string $name
 * @property string|null $color
 */
#[Fillable(['name', 'color'])]
class Tag extends Model
{
    use HasUlids;

    protected $attributes = ['color' => null];

    /** @return BelongsToMany<Transaction, $this> */
    public function transactions(): BelongsToMany
    {
        return $this->belongsToMany(Transaction::class, 'transaction_tags');
    }
}
