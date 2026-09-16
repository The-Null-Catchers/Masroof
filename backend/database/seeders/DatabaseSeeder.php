<?php

namespace Database\Seeders;

use Database\Seeders\Demo\DemoUserSeeder;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        if (app()->isProduction()) {
            // No console command when seeded programmatically (e.g. in tests).
            $this->command?->warn( // @phpstan-ignore nullsafe.neverNull
                'Demo data is never seeded in production.');

            return;
        }

        $this->call(DemoUserSeeder::class);
    }
}
