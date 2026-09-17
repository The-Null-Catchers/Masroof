<?php

namespace App\Http\Controllers\Api\V1;

use App\Enums\CategoryType;
use App\Http\Controllers\Concerns\ResolvesClientIds;
use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\CategoryRequest;
use App\Http\Resources\V1\CategoryResource;
use App\Models\Category;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;
use Illuminate\Validation\Rule;

class CategoryController extends Controller
{
    use ResolvesClientIds;

    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate([
            'type' => ['sometimes', Rule::enum(CategoryType::class)],
            'include_archived' => ['sometimes', 'boolean'],
        ]);

        $categories = $request->user()->categories()
            ->when($request->filled('type'), fn ($q) => $q->where('type', $request->input('type')))
            ->when(! $request->boolean('include_archived'), fn ($q) => $q->whereNull('archived_at'))
            ->orderBy('type')
            ->orderBy('sort_order')
            ->orderBy('name')
            ->get();

        return CategoryResource::collection($categories);
    }

    public function store(CategoryRequest $request): JsonResponse
    {
        if ($existing = $this->existingClientRecord($request, Category::class)) {
            return (new CategoryResource($existing))->response();
        }

        $category = $request->user()->categories()->make($request->safe()->except(['archived', 'id']));
        if ($request->filled('id')) {
            $category->id = $request->input('id');
        }
        $category->archived_at = $request->boolean('archived') ? now() : null;
        $category->save();

        return (new CategoryResource($category))->response()->setStatusCode(201);
    }

    public function show(Category $category): CategoryResource
    {
        Gate::authorize('view', $category);

        return new CategoryResource($category);
    }

    public function update(CategoryRequest $request, Category $category): CategoryResource
    {
        Gate::authorize('update', $category);

        $category->fill($request->safe()->except(['archived', 'id']));
        if ($category->isDirty('name')) {
            // A renamed built-in category is now user-owned text; stop auto-localizing it.
            $category->default_key = null;
        }
        if ($request->has('archived')) {
            $category->archived_at = $request->boolean('archived') ? ($category->archived_at ?? now()) : null;
        }
        $category->save();

        return new CategoryResource($category);
    }

    public function destroy(Request $request, Category $category): JsonResponse
    {
        Gate::authorize('delete', $category);

        $request->validate([
            'replacement_id' => [
                'sometimes', 'nullable', 'ulid',
                Rule::exists('categories', 'id')
                    ->where('user_id', $request->user()?->id)
                    ->where('type', $category->type->value)
                    ->whereNull('deleted_at'),
                Rule::notIn([$category->id]),
            ],
        ]);

        DB::transaction(function () use ($request, $category) {
            // Reassign history so reports keep their totals; otherwise it becomes uncategorized.
            $category->transactions()->update(['category_id' => $request->input('replacement_id')]);
            // Subcategories survive as top-level categories.
            $category->children()->update(['parent_id' => null]);
            $category->delete();
        });

        return response()->json(null, 204);
    }
}
