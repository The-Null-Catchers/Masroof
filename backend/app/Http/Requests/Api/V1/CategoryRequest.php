<?php

namespace App\Http\Requests\Api\V1;

use App\Enums\CategoryType;
use App\Models\Category;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class CategoryRequest extends FormRequest
{
    /** @return array<string, mixed> */
    public function rules(): array
    {
        $creating = $this->isMethod('post');
        $required = $creating ? 'required' : 'sometimes';
        /** @var Category|null $category */
        $category = $this->route('category');

        return [
            'id' => ['sometimes', 'ulid'],
            'name' => [$required, 'string', 'min:1', 'max:60'],
            'type' => [$creating ? 'required' : 'prohibited', Rule::enum(CategoryType::class)],
            'parent_id' => [
                'sometimes', 'nullable', 'ulid',
                Rule::exists('categories', 'id')
                    ->where('user_id', $this->user()?->getAuthIdentifier())
                    ->whereNull('parent_id')
                    ->whereNull('deleted_at'),
                Rule::notIn(array_filter([$category?->id])),
            ],
            'color' => ['sometimes', 'nullable', 'string', 'regex:/^#[0-9A-Fa-f]{6}$/'],
            'icon' => ['sometimes', 'nullable', 'string', 'max:40', 'regex:/^[a-z0-9_]+$/'],
            'sort_order' => ['sometimes', 'integer', 'min:0', 'max:100000'],
            'archived' => ['sometimes', 'boolean'],
        ];
    }

    /** @return array<int, callable> */
    public function after(): array
    {
        return [function (Validator $validator) {
            if ($validator->errors()->isNotEmpty() || ! $this->filled('parent_id')) {
                return;
            }

            /** @var Category|null $category */
            $category = $this->route('category');
            $parent = Category::query()->find($this->input('parent_id'));
            $type = $this->input('type', $category?->type->value);

            if ($parent && $parent->type->value !== $type) {
                $validator->errors()->add('parent_id', __('masroof.category_parent_type_mismatch'));
            }
            // Only two levels are supported: a category with children cannot become a child.
            if ($category && $category->children()->exists()) {
                $validator->errors()->add('parent_id', __('masroof.category_has_children'));
            }
        }];
    }
}
