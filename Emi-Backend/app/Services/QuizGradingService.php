<?php

namespace App\Services;

use App\Models\QuizAttempt;
use Illuminate\Support\Facades\DB;

class QuizGradingService
{
    public function __construct(private readonly ShortAnswerGradingService $shortAnswerGradingService) {}

    public function finalize(QuizAttempt $attempt, string $status = 'submitted'): QuizAttempt
    {
        return DB::transaction(function () use ($attempt, $status) {
            $attempt = QuizAttempt::query()->lockForUpdate()->with(['classQuiz.questions.options', 'answers.selectedOption'])->findOrFail($attempt->id);
            $answers = $attempt->answers->keyBy('quiz_question_id');
            $score = 0.0;
            $max = 0.0;
            $correct = 0;
            $incorrect = 0;
            $unanswered = 0;

            foreach ($attempt->classQuiz->questions as $question) {
                $max += (float) $question->points;
                $answer = $answers->get($question->id);

                if (! $answer) {
                    $unanswered++;

                    continue;
                }

                $isCorrect = false;
                $similarity = null;
                $normalized = null;

                if ($question->question_type === 'multiple_choice') {
                    $selected = $question->options->firstWhere('id', $answer->selected_option_id);
                    $isCorrect = (bool) ($selected?->is_correct);
                } else {
                    [$isCorrect, $similarity, $normalized] = $this->shortAnswerGradingService->grade(
                        $answer->answer_text,
                        (string) $question->correct_answer_text,
                        (bool) $question->use_fuzzy_matching,
                        $question->fuzzy_threshold,
                    );
                }

                $points = $isCorrect ? (float) $question->points : 0.0;
                $score += $points;
                $isCorrect ? $correct++ : $incorrect++;

                $answer->forceFill([
                    'normalized_answer' => $normalized,
                    'is_correct' => $isCorrect,
                    'similarity_score' => $similarity,
                    'awarded_points' => $points,
                    'max_points' => $question->points,
                ])->save();
            }

            $attempt->forceFill([
                'status' => $status,
                'submitted_at' => $attempt->submitted_at ?? now(),
                'score_points' => $score,
                'max_points' => $max,
                'score_percent' => $max > 0 ? round(($score / $max) * 100, 2) : 0,
                'correct_count' => $correct,
                'incorrect_count' => $incorrect,
                'unanswered_count' => $unanswered,
            ])->save();

            return $attempt->refresh()->load('classQuiz', 'answers.selectedOption', 'answers.question');
        });
    }
}
