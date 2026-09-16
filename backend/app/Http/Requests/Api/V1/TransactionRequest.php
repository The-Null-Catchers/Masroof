<?php

namespace App\Http\Requests\Api\V1;

use App\Enums\TransactionType;
use App\Models\Account;
use App\Models\Category;
use App\Models\Transaction;
use App\Support\Money;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Support\Carbon;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class TransactionRequest extends FormRequest
{
    /** @return array<string, mixed> */
    public function rules(): array
    {
        $creating = $this->isMethod('post');
        $required = $creating ? 'required' : 'sometimes';
        $userId = $this->user()?->getAuthIdentifier();
        $ownedAccount = Rule::exists('accounts', 'id')->where('user_id', $userId)->whereNull('deleted_at');

        return [
            'id' => ['sometimes', 'ulid'],
            'type' => [$required, Rule::enum(TransactionType::class)],
            'account_id' => [$required, 'ulid', $ownedAccount],
            'category_id' => ['sometimes', 'nullable', 'ulid', Rule::exists('categories', 'id')->where('user_id', $userId)->whereNull('deleted_at')],
            'amount' => [$required, 'string'],
            'transfer_account_id' => ['sometimes', 'nullable', 'ulid', $ownedAccount],
            'transfer_amount' => ['sometimes', 'nullable', 'string'],
            'occurred_at' => [$required, 'date'],
            'payee' => ['sometimes', 'nullable', 'string', 'max:120'],
            'note' => ['sometimes', 'nullable', 'string', 'max:1000'],
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

    /**
     * The transaction state after applying this request on top of the existing record.
     *
     * @return array<string, mixed>
     */
    private function resulting(): array
    {
        /** @var Transaction|null $existing */
        $existing = $this->route('transaction');
        $base = $existing ? [
            'type' => $existing->type->value,
            'account_id' => $existing->account_id,
            'category_id' => $existing->category_id,
            'transfer_account_id' => $existing->transfer_account_id,
            'amount' => null,
            'transfer_amount' => null,
        ] : [];

        return array_merge($base, $this->only(array_keys($this->rules())));
    }

    /** @return array<int, callable> */
    public function after(): array
    {
        return [function (Validator $validator) {
            if ($validator->errors()->isNotEmpty()) {
                return;
            }

            /** @var Transaction|null $existing */
            $existing = $this->route('transaction');
            $state = $this->resulting();
            $type = TransactionType::from($state['type']);
            $account = Account::query()->find($state['account_id']);

            if (! $account) {
                return;
            }

            $accountChanged = ! $existing || $existing->account_id !== $account->id;
            if ($accountChanged && $account->isArchived()) {
                $validator->errors()->add('account_id', __('masroof.account_archived'));
            }

            if ($this->has('amount')) {
                $this->validateAmount($validator, 'amount', $this->input('amount'), $account->currency);
            } elseif ($existing && $existing->currency !== $account->currency) {
                // Moving to an account in another currency requires re-entering the amount.
                $validator->errors()->add('amount', __('validation.required', ['attribute' => __('validation.attributes.amount')]));
            }

            if ($this->filled('occurred_at') && Carbon::parse($this->input('occurred_at'))->isAfter(now()->addYear())) {
                $validator->errors()->add('occurred_at', __('masroof.date_too_far'));
            }

            if ($type === TransactionType::Transfer) {
                $this->validateTransfer($validator, $state, $account);

                return;
            }

            if ($this->filled('transfer_account_id') || $this->filled('transfer_amount')) {
                $validator->errors()->add('transfer_account_id', __('masroof.transfer_fields_not_allowed'));
            }

            if (empty($state['category_id'])) {
                $validator->errors()->add('category_id', __('validation.required', ['attribute' => __('validation.attributes.category_id')]));

                return;
            }

            $category = Category::query()->find($state['category_id']);
            if ($category && $category->type->value !== $type->value) {
                $validator->errors()->add('category_id', __('masroof.category_type_mismatch'));
            }
        }];
    }

    /** @param  array<string, mixed>  $state */
    private function validateTransfer(Validator $validator, array $state, Account $source): void
    {
        if ($this->filled('category_id')) {
            $validator->errors()->add('category_id', __('masroof.transfer_category_not_allowed'));
        }

        if (empty($state['transfer_account_id'])) {
            $validator->errors()->add('transfer_account_id', __('validation.required', ['attribute' => __('validation.attributes.transfer_account_id')]));

            return;
        }

        $destination = Account::query()->find($state['transfer_account_id']);
        if (! $destination) {
            return;
        }

        if ($destination->id === $source->id) {
            $validator->errors()->add('transfer_account_id', __('masroof.transfer_same_account'));
        }

        /** @var Transaction|null $existing */
        $existing = $this->route('transaction');
        if ((! $existing || $existing->transfer_account_id !== $destination->id) && $destination->isArchived()) {
            $validator->errors()->add('transfer_account_id', __('masroof.account_archived'));
        }

        if ($destination->currency !== $source->currency) {
            if ($this->filled('transfer_amount')) {
                $this->validateAmount($validator, 'transfer_amount', $this->input('transfer_amount'), $destination->currency);
            } elseif (! $existing || $existing->transfer_account_id !== $destination->id || $existing->account_id !== $source->id) {
                $validator->errors()->add('transfer_amount', __('masroof.transfer_amount_required'));
            }
        }
    }

    private function validateAmount(Validator $validator, string $field, mixed $value, string $currency): void
    {
        $exponent = Money::exponent($currency);

        if (! is_string($value) || ! preg_match(Money::pattern($exponent), $value)) {
            $validator->errors()->add($field, __('masroof.invalid_amount', ['decimals' => $exponent]));

            return;
        }

        $minor = Money::toMinor($value, $currency);
        if ($minor <= 0) {
            $validator->errors()->add($field, __('masroof.amount_positive'));
        } elseif ($minor > config('masroof.max_amount') * (10 ** $exponent)) {
            $validator->errors()->add($field, __('masroof.amount_too_large'));
        }
    }

    /**
     * Attributes for TransactionService with amounts converted to minor units.
     *
     * @return array<string, mixed>
     */
    public function toAttributes(): array
    {
        /** @var Transaction|null $existing */
        $existing = $this->route('transaction');
        $data = $this->validated();
        $state = $this->resulting();
        $account = Account::query()->findOrFail($state['account_id']);

        if (array_key_exists('amount', $data)) {
            $data['amount'] = Money::toMinor($data['amount'], $account->currency);
        }

        if (! empty($data['transfer_amount']) && ! empty($state['transfer_account_id'])) {
            $destination = Account::query()->findOrFail($state['transfer_account_id']);
            $data['transfer_amount'] = Money::toMinor($data['transfer_amount'], $destination->currency);
        } elseif ($existing === null) {
            unset($data['transfer_amount']);
        }

        if (isset($data['occurred_at'])) {
            $data['occurred_at'] = Carbon::parse($data['occurred_at'])->utc();
        }

        return $data;
    }
}
