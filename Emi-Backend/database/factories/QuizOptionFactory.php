<?php

namespace Database\Factories;

use App\Models\QuizOption;
use App\Models\QuizQuestion;
use Illuminate\Database\Eloquent\Factories\Factory;

/** @extends Factory<QuizOption> */
class QuizOptionFactory extends Factory
{
    protected $model = QuizOption::class;

    public function definition(): array
    {
        return [
            'quiz_question_id' => QuizQuestion::factory()->multipleChoice(),
            'source_quiz_template_option_id' => null,
            'option_text' => 'Makan',
            'is_correct' => true,
            'order_number' => 1,
        ];
    }
}
