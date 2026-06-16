<?php

namespace App\Services;

use App\Models\SchoolClass;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class StudentDashboardService
{
    public function __construct(private readonly LearningProgressReportService $learningReports, private readonly QuizResultReportService $quizReports) {}

    public function summary(User $student, ?SchoolClass $class): array
    {
        if (! $class) {
            return [
                'class' => null,
                'empty_state' => true,
                'learning' => ['published_modules' => 0, 'not_started_modules' => 0, 'in_progress_modules' => 0, 'completed_modules' => 0, 'overall_progress_percent' => 0, 'completed_lessons' => 0, 'total_lessons' => 0],
                'quizzes' => ['available' => 0, 'upcoming' => 0, 'in_progress_attempts' => 0, 'completed' => 0, 'visible_result_count' => 0, 'hidden_result_count' => 0, 'visible_average_score' => null],
                'upcoming_deadlines' => [],
                'recent_activity' => [],
                'capabilities' => ['speaking_reports' => false],
                'speaking_summary' => null,
                'generated_at' => now('UTC')->toISOString(),
            ];
        }

        $progress = $this->learningReports->studentRows([], $class->id, $student->id, false)->first();
        $visibleSummary = $this->quizReports->summary([], $class->id, $student->id, true);
        $allSummary = $this->quizReports->summary([], $class->id, $student->id);

        return [
            'class' => ['id' => $class->id, 'name' => $class->name, 'school' => ['id' => $class->school?->id, 'name' => $class->school?->name]],
            'empty_state' => false,
            'learning' => [
                'published_modules' => $progress['published_modules'] ?? 0,
                'not_started_modules' => $progress['not_started_modules'] ?? 0,
                'in_progress_modules' => $progress['in_progress_modules'] ?? 0,
                'completed_modules' => $progress['completed_modules'] ?? 0,
                'overall_progress_percent' => $progress['overall_learning_progress_percent'] ?? 0,
                'completed_lessons' => $progress['completed_lessons'] ?? 0,
                'total_lessons' => $progress['total_published_lessons'] ?? 0,
            ],
            'quizzes' => [
                'available' => DB::table('class_quizzes')->where('class_id', $class->id)->where('status', 'published')->whereNull('deleted_at')->count(),
                'upcoming' => DB::table('class_quizzes')->where('class_id', $class->id)->where('status', 'published')->whereNull('deleted_at')->where('open_at', '>', now())->count(),
                'in_progress_attempts' => DB::table('quiz_attempts as qa')->join('class_quizzes as cq', 'cq.id', '=', 'qa.class_quiz_id')->where('qa.student_id', $student->id)->where('cq.class_id', $class->id)->where('qa.status', 'in_progress')->count(),
                'completed' => $allSummary['finalized_students'],
                'visible_result_count' => $visibleSummary['finalized_students'],
                'hidden_result_count' => max(0, $allSummary['finalized_students'] - $visibleSummary['finalized_students']),
                'visible_average_score' => $visibleSummary['average_best_score_percent'],
            ],
            'upcoming_deadlines' => DB::table('class_quizzes')->where('class_id', $class->id)->where('status', 'published')->whereNull('deleted_at')->whereNotNull('close_at')->where('close_at', '>=', now())->orderBy('close_at')->limit(5)->get(['id', 'title', 'close_at'])->all(),
            'recent_activity' => [],
            'capabilities' => ['speaking_reports' => false],
            'speaking_summary' => null,
            'generated_at' => now('UTC')->toISOString(),
        ];
    }
}
