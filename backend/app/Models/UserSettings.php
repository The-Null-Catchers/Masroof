<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * @property string $user_id
 * @property int|null $monthly_income_estimate
 * @property string|null $main_goal
 * @property bool $budget_alerts
 * @property bool $recurring_reminders
 * @property string|null $default_account_id
 * @property int $month_start_day
 * @property Carbon|null $onboarding_completed_at
 */
#[Fillable(['monthly_income_estimate', 'main_goal', 'budget_alerts', 'recurring_reminders', 'default_account_id', 'month_start_day'])]
class UserSettings extends Model
{
    protected $table = 'user_settings';

    protected $primaryKey = 'user_id';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $attributes = [
        'monthly_income_estimate' => null,
        'main_goal' => null,
        'budget_alerts' => true,
        'recurring_reminders' => true,
        'default_account_id' => null,
        'month_start_day' => 1,
        'onboarding_completed_at' => null,
    ];

    protected function casts(): array
    {
        return [
            'monthly_income_estimate' => 'integer',
            'budget_alerts' => 'boolean',
            'recurring_reminders' => 'boolean',
            'month_start_day' => 'integer',
            'onboarding_completed_at' => 'datetime',
        ];
    }

    /** @return BelongsTo<User, $this> */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
