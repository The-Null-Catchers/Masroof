<?php

namespace App\Policies;

use App\Models\Transaction;
use App\Models\User;
use Illuminate\Auth\Access\Response;

/**
 * Users may only touch their own records. Foreign records respond as 404 so
 * the API never reveals whether another user's identifier exists.
 */
class TransactionPolicy
{
    public function view(User $user, Transaction $transaction): Response
    {
        return $this->owns($user, $transaction);
    }

    public function update(User $user, Transaction $transaction): Response
    {
        return $this->owns($user, $transaction);
    }

    public function delete(User $user, Transaction $transaction): Response
    {
        return $this->owns($user, $transaction);
    }

    private function owns(User $user, Transaction $transaction): Response
    {
        return $transaction->user_id === $user->id ? Response::allow() : Response::denyAsNotFound();
    }
}
