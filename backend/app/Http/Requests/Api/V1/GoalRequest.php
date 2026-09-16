<?php

namespace App\Http\Requests\Api\V1;

use App\Models\Goal;
use App\Support\Money;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class GoalRequest extends FormRequest
{
    /** @return array<string, mixed> */
    public function rules(): array
    {
        $creating = $this->isMethod('post');
        $required = $creating ? 'required' : 'sometimes';

        return [
            'name' => [$required, 'string', 'min:1', 'max:60'],
            'kind' => ['sometimes', Rule::in(Goal::KINDS)],
            // Currency is fixed after creation because entries are stored in it.
            'currency' => [$creating ? 'required' : 'prohibited', 'string', 'size:3', Rule::in(array_keys(config('masroof.currencies')))],
            'target_amount' => [$required, 'string'],
            'target_date' => ['sometimes', 'nullable', 'date_format:Y-m-d'],
            'account_id' => ['sometimes', 'nullable', 'ulid', Rule::exists('accounts', 'id')->where('user_id', $this->user()?->getAuthIdentifier())->whereNull('deleted_at')],
            'icon' => ['sometimes', 'nullable', 'string', 'max:40', 'regex:/^[a-z0-9_]+$/'],
            'color' => ['sometimes', 'nullable', 'regex:/^#[0-9A-Fa-f]{6}$/'],
            'notes' => ['sometimes', 'nullable', 'string', 'max:1000'],
            'archived' => ['sometimes', 'boolean'],
        ];
    }

    protected function prepareForValidation(): void
    {
        if (is_int($this->input('target_amount')) || is_float($this->input('target_amount'))) {
            $this->merge(['target_amount' => (string) $this->input('target_amount')]);
        }
    }

    /** @return array<int, callable> */
    public function after(): array
    {
        return [function (Validator $validator) {
            if ($validator->errors()->hasAny(['currency', 'target_amount']) || ! $this->has('target_amount') || $this->currency() === '') {
                return;
            }
            $currency = $this->currency();
            $exp = Money::exponent($currency);
            $amount = (string) $this->input('target_amount');
            if (! preg_match(Money::pattern($exp), $amount) || Money::toMinor($amount, $currency) <= 0) {
                $validator->errors()->add('target_amount', __('masroof.invalid_amount', ['decimals' => $exp]));
            }
        }];
    }

    public function currency(): string
    {
        /** @var Goal|null $goal */
        $goal = $this->route('goal');

        return (string) ($goal->currency ?? $this->input('currency'));
    }

    /** @return array<string, mixed> */
    public function toAttributes(): array
    {
        $data = $this->safe()->except(['archived', 'target_amount']);
        if ($this->has('target_amount')) {
            $data['target_amount'] = Money::toMinor((string) $this->input('target_amount'), $this->currency());
        }

        return $data;
    }
}
