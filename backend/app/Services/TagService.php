<?php

namespace App\Services;

use App\Models\Tag;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class TagService
{
    /**
     * Resolves tag names to ids, creating missing tags. Matching ignores case
     * and surrounding whitespace so "Work" and "work " are the same tag.
     *
     * @param  array<int, string>  $names
     * @return array<int, string>
     */
    public function resolve(User $user, array $names): array
    {
        $normalized = collect($names)
            ->map(fn (string $name) => Str::squish($name))
            ->filter()
            ->unique(fn (string $name) => mb_strtolower($name))
            ->values();

        if ($normalized->isEmpty()) {
            return [];
        }

        $existing = $user->tags()
            ->whereIn(DB::raw('lower(name)'), $normalized->map(fn ($n) => mb_strtolower($n))->all())
            ->get()
            ->keyBy(fn (Tag $tag) => mb_strtolower($tag->name));

        return $normalized->map(function (string $name) use ($user, $existing) {
            $tag = $existing->get(mb_strtolower($name)) ?? $user->tags()->create(['name' => $name]);

            return $tag->id;
        })->all();
    }
}
