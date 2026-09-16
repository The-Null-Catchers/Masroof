<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Tag;
use Illuminate\Database\Query\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class TagController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $tags = $request->user()->tags()
            ->withCount('transactions')
            ->orderBy('name')
            ->get()
            ->map(fn (Tag $tag) => ['id' => $tag->id, 'name' => $tag->name, 'color' => $tag->color, 'transactions_count' => $tag->getAttribute('transactions_count')]);

        return response()->json(['data' => $tags]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $this->validated($request);
        $tag = $request->user()->tags()->create($data);

        return response()->json(['data' => $tag->only(['id', 'name', 'color'])], 201);
    }

    public function update(Request $request, Tag $tag): JsonResponse
    {
        abort_unless($tag->user_id === $request->user()->id, 404);
        $tag->fill($this->validated($request, $tag))->save();

        return response()->json(['data' => $tag->only(['id', 'name', 'color'])]);
    }

    public function destroy(Request $request, Tag $tag): JsonResponse
    {
        abort_unless($tag->user_id === $request->user()->id, 404);
        $tag->delete();

        return response()->json(null, 204);
    }

    /** @return array<string, mixed> */
    private function validated(Request $request, ?Tag $tag = null): array
    {
        $request->merge(['name' => Str::squish((string) $request->input('name'))]);
        $userId = $request->user()->id;

        return $request->validate([
            'name' => [
                'required', 'string', 'min:1', 'max:40',
                function (string $attribute, string $value, \Closure $fail) use ($userId, $tag) {
                    $taken = DB::table('tags')
                        ->where('user_id', $userId)
                        ->whereRaw('lower(name) = ?', [mb_strtolower($value)])
                        ->when($tag, fn (Builder $q) => $q->where('id', '!=', $tag->id))
                        ->exists();
                    if ($taken) {
                        $fail(__('validation.unique', ['attribute' => __('validation.attributes.name')]));
                    }
                },
            ],
            'color' => ['sometimes', 'nullable', 'regex:/^#[0-9A-Fa-f]{6}$/'],
        ]);
    }
}
