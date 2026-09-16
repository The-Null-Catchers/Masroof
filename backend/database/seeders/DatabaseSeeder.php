<?php

namespace Database\Seeders;

use Database\Seeders\Demo\DemoUserSeeder;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        if (app()->isProduction()) {
            $this->command?->warn('Demo data is never seeded in production.');

            return;
        }

        $this->call(DemoUserSeeder::class);
    }
}
