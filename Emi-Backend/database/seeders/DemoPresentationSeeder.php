<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class DemoPresentationSeeder extends Seeder
{
    public function run(): void
    {
        DB::transaction(function (): void {
            $this->call([
                DemoAccountSeeder::class,
                DemoSchoolClassSeeder::class,
                DemoDictionarySeeder::class,
                DemoKnowledgeSeeder::class,
                DemoLearningSeeder::class,
                DemoQuizSeeder::class,
                DemoSpeakingSeeder::class,
                DemoCultureSeeder::class,
                DemoProgressSeeder::class,
            ]);
        });
    }
}
