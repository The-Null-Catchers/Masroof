<?php

namespace Database\Seeders\Demo;

use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Database\Seeder;

/**
 * Local administrator for the admin dashboard.
 *
 * Login: admin@masroof.app / password1
 */
class AdminUserSeeder extends Seeder
{
    public const EMAIL = 'admin@masroof.app';

    public function run(): void
    {
        $admin = User::query()->firstOrCreate(['email' => self::EMAIL], [
            'name' => 'Masroof Admin', 'password' => 'password1', 'locale' => 'en', 'currency' => 'ILS', 'timezone' => 'Asia/Hebron',
        ]);
        $admin->forceFill(['role' => UserRole::Admin, 'email_verified_at' => $admin->email_verified_at ?? now()])->save();
        $admin->settingsOrDefault()->forceFill(['onboarding_completed_at' => now()])->save();
    }
}
