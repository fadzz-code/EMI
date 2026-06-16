<?php

namespace Database\Factories;

use App\Models\QuizTemplate;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/** @extends Factory<QuizTemplate> */
class QuizTemplateFactory extends Factory
{
    protected $model = QuizTemplate::class;

    public function definition(): array
    {
        return [
            'title' => 'Kuis Kosakata',
            'description' => 'Evaluasi kosakata.',
            'instructions' => 'Kerjakan dengan teliti.',
            'duration_minutes' => 30,
            'max_attempts' => 1,
            'show_result' => true,
            'status' => 'draft',
            'created_by' => User::factory()->admin(),
        ];
    }

    public function published(): static
    {
        return $this->state(fn (): array => ['status' => 'published', 'published_at' => now()]);
    }
}
