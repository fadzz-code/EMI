<?php

namespace Database\Factories;

use App\Models\QuizTemplate;
use App\Models\QuizTemplateQuestion;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/** @extends Factory<QuizTemplateQuestion> */
class QuizTemplateQuestionFactory extends Factory
{
    protected $model = QuizTemplateQuestion::class;

    public function definition(): array
    {
        return [
            'quiz_template_id' => QuizTemplate::factory(),
            'question_type' => 'short_answer',
            'question_text' => 'Tuliskan bahasa Mekongga dari makan.',
            'image_media_id' => null,
            'correct_answer_text' => 'monga',
            'use_fuzzy_matching' => false,
            'fuzzy_threshold' => null,
            'points' => 10,
            'order_number' => 1,
            'explanation' => 'Monga berarti makan.',
            'created_by' => User::factory()->admin(),
        ];
    }

    public function multipleChoice(): static
    {
        return $this->state(fn (): array => [
            'question_type' => 'multiple_choice',
            'correct_answer_text' => null,
            'use_fuzzy_matching' => false,
            'fuzzy_threshold' => null,
        ]);
    }
}
