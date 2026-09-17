<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUlids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * @property string $id
 * @property string $user_id
 * @property string|null $transaction_id
 * @property string $file_path
 * @property string $mime_type
 * @property int $size
 * @property string $status
 * @property string|null $ocr_provider
 * @property string|null $raw_text
 * @property array<string, mixed>|null $extracted
 * @property string|null $error
 * @property Carbon|null $processed_at
 * @property Carbon|null $created_at
 */
class Receipt extends Model
{
    use HasUlids;

    protected $guarded = ['id', 'user_id'];

    protected $attributes = [
        'transaction_id' => null,
        'status' => 'uploaded',
        'ocr_provider' => null,
        'raw_text' => null,
        'extracted' => null,
        'error' => null,
        'processed_at' => null,
    ];

    protected function casts(): array
    {
        return ['size' => 'integer', 'extracted' => 'array', 'processed_at' => 'datetime'];
    }

    /** @return BelongsTo<User, $this> */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /** @return BelongsTo<Transaction, $this> */
    public function transaction(): BelongsTo
    {
        return $this->belongsTo(Transaction::class);
    }
}
