<?php

namespace App\Http\Requests\Api\V1;

use App\Enums\TransactionType;
use App\Models\Account;
use App\Models\Category;
use App\Models\RecurringTransaction;
use App\Support\Money;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class RecurringTransactionRequest extends FormRequest
{
    /** @return array<string, mixed> */
    public function rules(): array
    {
        $creating = $this->isMethod('post');
        $required = $creating ? 'required' : 'sometimes';
        $userId = $this->user()?->getAuthIdentifier();
        $ownedAccount = Rule::exists('accounts', 'id')->where('user_id', $userId)->whereNull('deleted_at');

        return [
            'name' => [$required, 'string', 'min:1', 'max:80'],
            'type' => [$required, Rule::enum(TransactionType::class)],
            'account_id' => [$required, 'ulid', $ownedAccount],
            'category_id' => ['sometimes', 'nullable', 'ulid', Rule::exists('categories', 'id')->where('user_id', $userId)->whereNull('deleted_at')],
            'transfer_account_id' => ['sometimes', 'nullable', 'ulid', $ownedAccount],
            'amount' => [$required, 'string'],
            'transfer_amount' => ['sometimes', 'nullable', 'string'],
            'merchant' => ['sometimes', 'nullable', 'string', 'max:120'],
            'payment_method' => ['sometimes', 'nullable', Rule::in(config('masroof.payment_methods'))],
            'note' => ['sometimes', 'nullable', 'string', 'max:1000'],
            'frequency' => [$required, Rule::in(RecurringTransaction::FREQUENCIES)],
            'interval' => ['sometimes', 'integer', 'between:1,366'],
            'starts_on' => [$required, 'date_format:Y-m-d'],
            'ends_on' => ['sometimes', 'nullable', 'date_format:Y-m-d', 'after_or_equal:starts_on'],
            'mode' => ['sometimes', Rule::in(['auto', 'remind'])],
            'remind_days_before' => ['sometimes', 'integer', 'between:0,14'],
            'paused' => ['sometimes', 'boolean'],
        ];
    }

    protected function prepareForValidation(): void
    {
        foreach (['amount', 'transfer_amount'] as $field) {
            if (is_int($this->input($field)) || is_float($this->input($field))) {
                $this->merge([$field => (string) $this->input($field)]);
            }
        }
    }

    /** @return array<string, mixed> */
    private function state(): array
    {
        /** @var RecurringTransaction|null $rule */
        $rule = $this->route('recurring');

        return array_merge($rule ? [
            'type' => $rule->type->value,
            'account_id' => $rule->account_id,
            'category_id' => $rule->category_id,
            'transfer_account_id' => $rule->transfer_account_id,
        ] : [], $this->only(['type', 'account_id', 'category_id', 'transfer_account_id']));
    }

    /** @return array<int, callable> */
    public function after(): array
    {
        return [function (Validator $validator) {
            if ($validator->errors()->isNotEmpty()) {
                return;
            }
            $state = $this->state();
            $account = Account::query()->find($state['account_id']);
            if ($account === null) {
                return;
            }

            if ($this->has('amount')) {
                $this->checkAmount($validator, 'amount', (string) $this->input('amount'), $account->currency);
            }

            if ($state['type'] === 'transfer') {
                $destination = Account::query()->find($state['transfer_account_id'] ?? null);
                if ($destination === null || $destination->id === $account->id) {
                    $validator->errors()->add('transfer_account_id', __('masroof.transfer_same_account'));
                } elseif ($destination->currency !== $account->currency && $this->filled('transfer_amount')) {
                    $this->checkAmount($validator, 'transfer_amount', (string) $this->input('transfer_amount'), $destination->currency);
                } elseif ($destination->currency !== $account->currency && $this->isMethod('post')) {
                    $validator->errors()->add('transfer_amount', __('masroof.transfer_amount_required'));
                }

                return;
            }

            $category = Category::query()->find($state['category_id'] ?? null);
            if ($category === null) {
                $validator->errors()->add('category_id', __('validation.required', ['attribute' => __('validation.attributes.category_id')]));
            } elseif ($category->type->value !== $state['type']) {
                $validator->errors()->add('category_id', __('masroof.category_type_mismatch'));
            }
        }];
    }

    private function checkAmount(Validator $validator, string $field, string $value, string $currency): void
    {
        $exp = Money::exponent($currency);
        if (! preg_match(Money::pattern($exp), $value) || Money::toMinor($value, $currency) <= 0) {
            $validator->errors()->add($field, __('masroof.invalid_amount', ['decimals' => $exp]));
        }
    }

    /** @return array<string, mixed> */
    public function toAttributes(): array
    {
        $state = $this->state();
        $account = Account::query()->findOrFail($state['account_id']);
        $data = $this->safe()->except(['paused', 'amount', 'transfer_amount']);
        $data['currency'] = $account->currency;

        if ($this->has('amount')) {
            $data['amount'] = Money::toMinor((string) $this->input('amount'), $account->currency);
        }
        if ($state['type'] === 'transfer') {
            $destination = Account::query()->findOrFail($state['transfer_account_id']);
            $data['category_id'] = null;
            if ($destination->currency === $account->currency) {
                $data['transfer_amount'] = $data['amount'] ?? null;
            } elseif ($this->filled('transfer_amount')) {
                $data['transfer_amount'] = Money::toMinor((string) $this->input('transfer_amount'), $destination->currency);
            }
        } else {
            $data['transfer_account_id'] = null;
            $data['transfer_amount'] = null;
        }

        return $data;
    }
}
