<?php

namespace Database\Factories;

use App\Models\ClassLesson;
use App\Models\LessonProgress;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/** @extends Factory<LessonProgress> */
class LessonProgressFactory extends Factory
{
    protected $model = LessonProgress::class;

    public function definition(): array
    {
        return [
            'student_id' => User::factory()->student()->approved(),
            'class_lesson_id' => ClassLesson::factory()->published(),
            'status' => 'not_started',
            'progress_percent' => 0,
        ];
    }
}
