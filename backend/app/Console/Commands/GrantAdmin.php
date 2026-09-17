<?php

namespace App\Console\Commands;

use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

#[Signature('masroof:admin {email : The user to promote} {--revoke : Remove admin rights instead}')]
#[Description('Grant or revoke administrator access. Admin rights cannot be granted through the API.')]
class GrantAdmin extends Command
{
    public function handle(): int
    {
        $user = User::query()->where('email', mb_strtolower((string) $this->argument('email')))->first();
        if ($user === null) {
            $this->error('No user with that email.');

            return self::FAILURE;
        }

        $user->forceFill(['role' => $this->option('revoke') ? UserRole::User : UserRole::Admin])->save();
        $this->info($this->option('revoke') ? "{$user->email} is no longer an admin." : "{$user->email} is now an admin.");

        return self::SUCCESS;
    }
}
