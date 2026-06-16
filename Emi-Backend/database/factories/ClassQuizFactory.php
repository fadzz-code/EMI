<?php

namespace Database\Factories;

use App\Models\ClassQuiz;
use App\Models\SchoolClass;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/** @extends Factory<ClassQuiz> */
class ClassQuizFactory extends Factory
{
    protected $model = ClassQuiz::class;

    public function definition(): array
    {
        return [
            'class_id' => SchoolClass::factory(),
            'source_quiz_template_id' => null,
            'title' => 'Kuis Kelas',
            'description' => 'Evaluasi kelas.',
            'instructions' => 'Kerjakan sendiri.',
            'duration_minutes' => 30,
            'max_attempts' => 1,
            'show_result' => true,
            'open_at' => null,
            'close_at' => null,
            'status' => 'draft',
            'created_by' => User::factory()->admin(),
        ];
    }

    public function published(): static
    {
        return $this->state(fn (): array => ['status' => 'published', 'published_at' => now()]);
    }
}
