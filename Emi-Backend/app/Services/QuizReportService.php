<?php

namespace App\Services;

use App\Models\ClassQuiz;
use App\Models\StudentClassMembership;

class QuizReportService
{
    public function summary(ClassQuiz $quiz): array
    {
        $quiz->load(['questions.options', 'attempts.answers.selectedOption']);
        $submitted = $quiz->attempts->whereIn('status', ['submitted', 'expired']);
        $scores = $submitted->pluck('score_percent');

        return [
            'class_quiz_id' => $quiz->id,
            'student_count' => StudentClassMembership::query()->where('class_id', $quiz->class_id)->where('is_active', true)->count(),
            'attempts_count' => $quiz->attempts->count(),
            'submitted_count' => $submitted->count(),
            'in_progress_count' => $quiz->attempts->where('status', 'in_progress')->count(),
            'average_score_percent' => $scores->isNotEmpty() ? round($scores->avg(), 2) : null,
            'highest_score_percent' => $scores->isNotEmpty() ? round($scores->max(), 2) : null,
            'lowest_score_percent' => $scores->isNotEmpty() ? round($scores->min(), 2) : null,
            'questions' => $quiz->questions->map(function ($question) use ($submitted) {
                $answers = $submitted->flatMap->answers->where('quiz_question_id', $question->id);

                return [
                    'id' => $question->id,
                    'question_type' => $question->question_type,
                    'order_number' => $question->order_number,
                    'points' => $question->points,
                    'answered_count' => $answers->count(),
                    'correct_count' => $answers->where('is_correct', true)->count(),
                    'incorrect_count' => $answers->where('is_correct', false)->count(),
                    'average_awarded_points' => $answers->isNotEmpty() ? round($answers->avg('awarded_points'), 2) : null,
                ];
            })->values(),
        ];
    }
}
