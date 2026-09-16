<?php

namespace App\Policies;

use App\Models\Category;
use App\Models\User;
use Illuminate\Auth\Access\Response;

/**
 * Users may only touch their own records. Foreign records respond as 404 so
 * the API never reveals whether another user's identifier exists.
 */
class CategoryPolicy
{
    public function view(User $user, Category $category): Response
    {
        return $this->owns($user, $category);
    }

    public function update(User $user, Category $category): Response
    {
        return $this->owns($user, $category);
    }

    public function delete(User $user, Category $category): Response
    {
        return $this->owns($user, $category);
    }

    private function owns(User $user, Category $category): Response
    {
        return $category->user_id === $user->id ? Response::allow() : Response::denyAsNotFound();
    }
}
