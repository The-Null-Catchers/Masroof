<?php

namespace App\Http\Requests\Api\V1;

use App\Models\Budget;
use App\Models\Category;
use App\Support\Money;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class BudgetRequest extends FormRequest
{
    /** @return array<string, mixed> */
    public function rules(): array
    {
        $creating = $this->isMethod('post');
        $required = $creating ? 'required' : 'sometimes';
        /** @var Budget|null $budget */
        $budget = $this->route('budget');
        $period = $this->input('period', $budget?->period);

        return [
            'name' => [$required, 'string', 'min:1', 'max:60'],
            'period' => [$required, Rule::in(['monthly', 'weekly', 'custom'])],
            'currency' => [$required, 'string', 'size:3', Rule::in(array_keys(config('masroof.currencies')))],
            'amount' => [$required, 'string'],
            'starts_on' => [$period === 'custom' && $creating ? 'required' : 'sometimes', 'nullable', 'date_format:Y-m-d'],
            'ends_on' => [$period === 'custom' && $creating ? 'required' : 'sometimes', 'nullable', 'date_format:Y-m-d', 'after_or_equal:starts_on'],
            'alert_thresholds' => ['sometimes', 'array', 'min:1', 'max:6'],
            'alert_thresholds.*' => ['integer', 'between:1,200', 'distinct'],
            'category_ids' => ['sometimes', 'array', 'max:50'],
            'category_ids.*' => ['ulid', Rule::exists('categories', 'id')->where('user_id', $this->user()?->getAuthIdentifier())->whereNull('deleted_at')],
            'archived' => ['sometimes', 'boolean'],
        ];
    }

    protected function prepareForValidation(): void
    {
        if (is_int($this->input('amount')) || is_float($this->input('amount'))) {
            $this->merge(['amount' => (string) $this->input('amount')]);
        }
        if (is_string($this->input('currency'))) {
            $this->merge(['currency' => strtoupper($this->input('currency'))]);
        }
    }

    /** @return array<int, callable> */
    public function after(): array
    {
        return [function (Validator $validator) {
            if ($validator->errors()->hasAny(['currency', 'amount', 'period', 'category_ids', 'category_ids.*'])) {
                return;
            }
            /** @var Budget|null $budget */
            $budget = $this->route('budget');
            $currency = $this->input('currency', $budget?->currency);
            $period = $this->input('period', $budget?->period);

            if ($this->has('amount')) {
                $exp = Money::exponent($currency);
                $amount = (string) $this->input('amount');
                if (! preg_match(Money::pattern($exp), $amount) || Money::toMinor($amount, $currency) <= 0) {
                    $validator->errors()->add('amount', __('masroof.invalid_amount', ['decimals' => $exp]));
                }
            }

            if ($period === 'custom' && ! ($this->input('starts_on', $budget?->starts_on) && $this->input('ends_on', $budget?->ends_on))) {
                $validator->errors()->add('starts_on', __('validation.required', ['attribute' => __('validation.attributes.starts_on')]));
            }

            $ids = $this->input('category_ids', []);
            if ($ids !== [] && Category::query()->whereIn('id', $ids)->where('type', '!=', 'expense')->exists()) {
                $validator->errors()->add('category_ids', __('masroof.budget_categories_expense_only'));
            }
        }];
    }

    /** @return array<string, mixed> */
    public function toAttributes(): array
    {
        /** @var Budget|null $budget */
        $budget = $this->route('budget');
        $data = $this->safe()->only(['name', 'period', 'currency', 'starts_on', 'ends_on', 'alert_thresholds']);
        if ($this->has('amount')) {
            $data['amount'] = Money::toMinor((string) $this->input('amount'), $this->input('currency', $budget?->currency));
        }
        if (($data['period'] ?? $budget?->period) !== 'custom') {
            $data['starts_on'] = null;
            $data['ends_on'] = null;
        }

        return $data;
    }
}
