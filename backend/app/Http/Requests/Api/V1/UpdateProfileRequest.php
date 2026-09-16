<?php

namespace App\Http\Requests\Api\V1;

use App\Support\Money;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProfileRequest extends FormRequest
{
    /** @return array<string, mixed> */
    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'string', 'min:2', 'max:100'],
            'locale' => ['sometimes', 'string', Rule::in(config('masroof.locales'))],
            'currency' => ['sometimes', 'string', 'size:3', fn ($attr, $value, $fail) => Money::isSupported((string) $value) || $fail(__('validation.in', ['attribute' => __('validation.attributes.currency')]))],
            'timezone' => ['sometimes', 'string', 'timezone:all'],
            'week_start' => ['sometimes', 'integer', 'between:0,6'],
        ];
    }
}
