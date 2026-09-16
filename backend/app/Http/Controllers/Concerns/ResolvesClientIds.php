<?php

namespace App\Http\Controllers\Concerns;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\SoftDeletingScope;
use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\ConflictHttpException;

/**
 * Offline clients generate ULIDs locally and may retry a create after a
 * dropped connection. A repeated create with an id the user already owns
 * returns the existing record instead of failing or duplicating it.
 */
trait ResolvesClientIds
{
    /**
     * @template TModel of Model
     *
     * @param  class-string<TModel>  $model
     * @return TModel|null
     */
    protected function existingClientRecord(Request $request, string $model): ?Model
    {
        $id = $request->input('id');
        if (! is_string($id) || $id === '') {
            return null;
        }

        $query = $model::query();
        if (in_array(SoftDeletes::class, class_uses_recursive($model), true)) {
            $query->withoutGlobalScope(SoftDeletingScope::class);
        }
        $existing = $query->find($id);

        if ($existing === null) {
            return null;
        }
        if ($existing->getAttribute('user_id') !== $request->user()->id) {
            throw new ConflictHttpException(__('masroof.id_conflict'));
        }

        return $existing;
    }
}
