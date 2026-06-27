<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call(AdminSeeder::class);

        if (app()->environment('local', 'testing', 'development')) {
            $this->call(DevAccountSeeder::class);
            $this->call(DevDemoDataSeeder::class);
        }
    }
}
