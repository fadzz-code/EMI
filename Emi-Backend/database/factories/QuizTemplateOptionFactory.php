<?php

namespace Database\Factories;

use App\Models\QuizTemplateOption;
use App\Models\QuizTemplateQuestion;
use Illuminate\Database\Eloquent\Factories\Factory;

/** @extends Factory<QuizTemplateOption> */
class QuizTemplateOptionFactory extends Factory
{
    protected $model = QuizTemplateOption::class;

    public function definition(): array
    {
        return [
            'quiz_template_question_id' => QuizTemplateQuestion::factory()->multipleChoice(),
            'option_text' => 'Makan',
            'is_correct' => true,
            'order_number' => 1,
        ];
    }
}
