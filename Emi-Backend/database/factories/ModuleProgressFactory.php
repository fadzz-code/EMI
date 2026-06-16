<?php

namespace Database\Factories;

use App\Models\ClassModule;
use App\Models\ModuleProgress;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/** @extends Factory<ModuleProgress> */
class ModuleProgressFactory extends Factory
{
    protected $model = ModuleProgress::class;

    public function definition(): array
    {
        return [
            'student_id' => User::factory()->student()->approved(),
            'class_module_id' => ClassModule::factory()->published(),
            'status' => 'not_started',
            'progress_percent' => 0,
            'completed_lessons' => 0,
            'total_lessons' => 0,
        ];
    }
}
