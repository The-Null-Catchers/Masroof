<?php

namespace App\Http\Requests\Api\V1;

use App\Enums\AccountType;
use App\Models\Account;
use App\Support\Money;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class AccountRequest extends FormRequest
{
    /** @return array<string, mixed> */
    public function rules(): array
    {
        $creating = $this->isMethod('post');
        $required = $creating ? 'required' : 'sometimes';

        return [
            'id' => ['sometimes', 'ulid'],
            'name' => [$required, 'string', 'min:1', 'max:60'],
            'type' => [$required, Rule::enum(AccountType::class)],
            // Currency is fixed once transactions exist; see after().
            'currency' => [$required, 'string', 'size:3', fn ($attr, $value, $fail) => Money::isSupported((string) $value) || $fail(__('validation.in', ['attribute' => __('validation.attributes.currency')]))],
            'opening_balance' => ['sometimes', 'nullable', 'string'],
            'color' => ['sometimes', 'nullable', 'string', 'regex:/^#[0-9A-Fa-f]{6}$/'],
            'icon' => ['sometimes', 'nullable', 'string', 'max:40', 'regex:/^[a-z0-9_]+$/'],
            'notes' => ['sometimes', 'nullable', 'string', 'max:1000'],
            'include_in_total' => ['sometimes', 'boolean'],
            'sort_order' => ['sometimes', 'integer', 'min:0', 'max:100000'],
            'archived' => ['sometimes', 'boolean'],
        ];
    }

    protected function prepareForValidation(): void
    {
        if (is_numeric($this->input('opening_balance'))) {
            $this->merge(['opening_balance' => (string) $this->input('opening_balance')]);
        }
        if (is_string($this->input('currency'))) {
            $this->merge(['currency' => strtoupper($this->input('currency'))]);
        }
    }

    /** @return array<int, callable> */
    public function after(): array
    {
        return [function (Validator $validator) {
            if ($validator->errors()->isNotEmpty()) {
                return;
            }

            /** @var Account|null $account */
            $account = $this->route('account');
            $currency = $this->input('currency', $account?->currency);

            if ($account && $currency !== $account->currency && ($account->transactions()->exists() || $account->incomingTransfers()->exists())) {
                $validator->errors()->add('currency', __('masroof.account_currency_locked'));
            }

            $opening = $this->input('opening_balance');
            if ($opening !== null && $currency && ! preg_match(Money::pattern(Money::exponent($currency), true), $opening)) {
                $validator->errors()->add('opening_balance', __('masroof.invalid_amount', ['decimals' => Money::exponent($currency)]));
            }
        }];
    }

    /** @return array<string, mixed> */
    public function toAttributes(): array
    {
        $data = $this->safe()->except(['archived', 'opening_balance', 'id']);
        /** @var Account|null $account */
        $account = $this->route('account');
        $currency = $this->input('currency', $account?->currency);

        if ($this->has('opening_balance')) {
            $data['opening_balance'] = Money::toMinor($this->input('opening_balance') ?? '0', $currency);
        }

        return $data;
    }
}
