<?php

namespace Database\Factories;

use App\Models\QuizAnswer;
use App\Models\QuizAttempt;
use App\Models\QuizQuestion;
use Illuminate\Database\Eloquent\Factories\Factory;

/** @extends Factory<QuizAnswer> */
class QuizAnswerFactory extends Factory
{
    protected $model = QuizAnswer::class;

    public function definition(): array
    {
        return [
            'quiz_attempt_id' => QuizAttempt::factory(),
            'quiz_question_id' => QuizQuestion::factory(),
            'selected_option_id' => null,
            'answer_text' => null,
            'normalized_answer' => null,
            'is_correct' => null,
            'similarity_score' => null,
            'awarded_points' => 0,
            'max_points' => 10,
            'answered_at' => null,
        ];
    }
}
