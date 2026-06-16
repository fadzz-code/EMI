<?php

namespace Database\Factories;

use App\Models\ClassQuiz;
use App\Models\QuizAttempt;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/** @extends Factory<QuizAttempt> */
class QuizAttemptFactory extends Factory
{
    protected $model = QuizAttempt::class;

    public function definition(): array
    {
        return [
            'class_quiz_id' => ClassQuiz::factory()->published(),
            'student_id' => User::factory()->student()->approved(),
            'attempt_number' => 1,
            'status' => 'in_progress',
            'started_at' => now(),
            'expires_at' => now()->addMinutes(30),
            'max_points' => 10,
        ];
    }
}
