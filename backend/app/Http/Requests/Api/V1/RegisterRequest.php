<?php

namespace App\Http\Requests\Api\V1;

use App\Support\Money;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

class RegisterRequest extends FormRequest
{
    /** @return array<string, mixed> */
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'min:2', 'max:100'],
            'email' => ['required', 'string', 'email:rfc', 'max:255', Rule::unique('users', 'email')],
            'password' => ['required', 'string', 'confirmed', Password::min(8)->letters()->numbers()],
            'locale' => ['sometimes', 'string', Rule::in(config('masroof.locales'))],
            'currency' => ['sometimes', 'string', 'size:3', fn ($attr, $value, $fail) => Money::isSupported((string) $value) || $fail(__('validation.in', ['attribute' => __('validation.attributes.currency')]))],
            'timezone' => ['sometimes', 'string', 'timezone:all'],
            'device_name' => ['required', 'string', 'max:100'],
        ];
    }

    protected function prepareForValidation(): void
    {
        if (is_string($this->input('email'))) {
            $this->merge(['email' => mb_strtolower(trim($this->input('email')))]);
        }
    }
}
