<?php

namespace App\Policies;

use App\Models\Account;
use App\Models\User;
use Illuminate\Auth\Access\Response;

/**
 * Users may only touch their own records. Foreign records respond as 404 so
 * the API never reveals whether another user's identifier exists.
 */
class AccountPolicy
{
    public function view(User $user, Account $account): Response
    {
        return $this->owns($user, $account);
    }

    public function update(User $user, Account $account): Response
    {
        return $this->owns($user, $account);
    }

    public function delete(User $user, Account $account): Response
    {
        return $this->owns($user, $account);
    }

    private function owns(User $user, Account $account): Response
    {
        return $account->user_id === $user->id ? Response::allow() : Response::denyAsNotFound();
    }
}
