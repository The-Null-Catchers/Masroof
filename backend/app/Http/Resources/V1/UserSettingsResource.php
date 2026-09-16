<?php

namespace App\Http\Resources\V1;

use App\Models\UserSettings;
use App\Support\Money;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin UserSettings */
class UserSettingsResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        $currency = $this->user->currency;

        return [
            'monthly_income_estimate' => $this->monthly_income_estimate !== null ? Money::toDecimal($this->monthly_income_estimate, $currency) : null,
            'monthly_income_estimate_minor' => $this->monthly_income_estimate,
            'main_goal' => $this->main_goal,
            'budget_alerts' => $this->budget_alerts,
            'recurring_reminders' => $this->recurring_reminders,
            'default_account_id' => $this->default_account_id,
            'month_start_day' => $this->month_start_day,
            'onboarding_completed' => $this->onboarding_completed_at !== null,
        ];
    }
}
