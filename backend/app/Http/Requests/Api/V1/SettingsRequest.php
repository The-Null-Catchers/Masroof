<?php

namespace App\Http\Requests\Api\V1;

use App\Support\Money;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

/**
 * Profile preferences and financial settings. Also used by onboarding,
 * where every field is optional so users can skip questions.
 */
class SettingsRequest extends FormRequest
{
    /** @return array<string, mixed> */
    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'string', 'min:2', 'max:100'],
            'locale' => ['sometimes', 'string', Rule::in(config('masroof.locales'))],
            'currency' => ['sometimes', 'string', 'size:3', Rule::in(array_keys(config('masroof.currencies')))],
            'timezone' => ['sometimes', 'string', 'timezone:all'],
            'week_start' => ['sometimes', 'integer', 'between:0,6'],
            'monthly_income_estimate' => ['sometimes', 'nullable', 'string'],
            'main_goal' => ['sometimes', 'nullable', Rule::in(config('masroof.financial_goals'))],
            'budget_alerts' => ['sometimes', 'boolean'],
            'recurring_reminders' => ['sometimes', 'boolean'],
            'default_account_id' => [
                'sometimes', 'nullable', 'ulid',
                Rule::exists('accounts', 'id')->where('user_id', $this->user()?->getAuthIdentifier())->whereNull('deleted_at'),
            ],
            'month_start_day' => ['sometimes', 'integer', 'between:1,28'],
        ];
    }

    protected function prepareForValidation(): void
    {
        if (is_int($this->input('monthly_income_estimate')) || is_float($this->input('monthly_income_estimate'))) {
            $this->merge(['monthly_income_estimate' => (string) $this->input('monthly_income_estimate')]);
        }
        if (is_string($this->input('currency'))) {
            $this->merge(['currency' => strtoupper($this->input('currency'))]);
        }
    }

    /** @return array<int, callable> */
    public function after(): array
    {
        return [function (Validator $validator) {
            $income = $this->input('monthly_income_estimate');
            if ($validator->errors()->isNotEmpty() || $income === null) {
                return;
            }
            $currency = $this->input('currency', $this->user()?->currency);
            if (! preg_match(Money::pattern(Money::exponent($currency)), $income)) {
                $validator->errors()->add('monthly_income_estimate', __('masroof.invalid_amount', ['decimals' => Money::exponent($currency)]));
            }
        }];
    }

    /** @return array<string, mixed> */
    public function profile(): array
    {
        return $this->safe()->only(['name', 'locale', 'currency', 'timezone', 'week_start']);
    }

    /** @return array<string, mixed> */
    public function settings(): array
    {
        $data = $this->safe()->only(['main_goal', 'budget_alerts', 'recurring_reminders', 'default_account_id', 'month_start_day']);
        if ($this->has('monthly_income_estimate')) {
            $income = $this->input('monthly_income_estimate');
            $currency = $this->input('currency', $this->user()?->currency);
            $data['monthly_income_estimate'] = $income === null ? null : Money::toMinor($income, $currency);
        }

        return $data;
    }
}
