<?php

namespace App\Services;

use App\Models\SchoolClass;
use Illuminate\Support\Facades\DB;

class TeacherDashboardService
{
    public function __construct(private readonly LearningProgressReportService $learningReports, private readonly QuizResultReportService $quizReports) {}

    public function summary(?SchoolClass $class): array
    {
        if (! $class) {
            return [
                'class' => null,
                'empty_state' => true,
                'students' => ['active' => 0, 'with_learning_activity' => 0, 'completed_all_modules' => 0],
                'learning' => ['published_modules' => 0, 'published_lessons' => 0, 'average_progress_percent' => 0],
                'quizzes' => ['published_quizzes' => 0, 'students_participated' => 0, 'final_attempts' => 0, 'average_score_percent' => null],
                'recent_activity' => [],
                'capabilities' => ['speaking_reports' => false],
                'speaking_summary' => null,
                'generated_at' => now('UTC')->toISOString(),
            ];
        }

        $quizSummary = $this->quizReports->summary([], $class->id);
        $studentRows = $this->learningReports->studentRows([], $class->id, null, false);

        return [
            'class' => ['id' => $class->id, 'name' => $class->name, 'school' => ['id' => $class->school?->id, 'name' => $class->school?->name]],
            'empty_state' => false,
            'students' => [
                'active' => $studentRows->count(),
                'with_learning_activity' => $studentRows->where('started_modules', '>', 0)->count(),
                'completed_all_modules' => $studentRows->filter(fn ($row) => $row['published_modules'] > 0 && $row['completed_modules'] === $row['published_modules'])->count(),
            ],
            'learning' => [
                'published_modules' => DB::table('class_modules')->where('class_id', $class->id)->where('status', 'published')->whereNull('deleted_at')->count(),
                'published_lessons' => DB::table('class_lessons as cl')->join('class_modules as cm', 'cm.id', '=', 'cl.class_module_id')->where('cm.class_id', $class->id)->where('cm.status', 'published')->whereNull('cm.deleted_at')->where('cl.status', 'published')->whereNull('cl.deleted_at')->count(),
                'average_progress_percent' => $this->learningReports->averageProgress(null, $class->id),
            ],
            'quizzes' => [
                'published_quizzes' => DB::table('class_quizzes')->where('class_id', $class->id)->where('status', 'published')->whereNull('deleted_at')->count(),
                'students_participated' => $quizSummary['participating_students'],
                'final_attempts' => $quizSummary['submitted_attempts'] + $quizSummary['expired_attempts'],
                'average_score_percent' => $quizSummary['average_best_score_percent'],
            ],
            'recent_activity' => $this->recentActivity($class->id),
            'capabilities' => ['speaking_reports' => false],
            'speaking_summary' => null,
            'generated_at' => now('UTC')->toISOString(),
        ];
    }

    private function recentActivity(string $classId): array
    {
        $modules = DB::table('module_progress as mp')
            ->join('users as u', 'u.id', '=', 'mp.student_id')
            ->join('class_modules as cm', 'cm.id', '=', 'mp.class_module_id')
            ->where('cm.class_id', $classId)
            ->where('mp.status', 'completed')
            ->selectRaw("'module_completed' as type, u.full_name as student_name, cm.title as title, mp.completed_at as occurred_at")
            ->orderByDesc('occurred_at')
            ->limit(5)
            ->get();

        $quizzes = DB::table('quiz_attempts as qa')
            ->join('users as u', 'u.id', '=', 'qa.student_id')
            ->join('class_quizzes as cq', 'cq.id', '=', 'qa.class_quiz_id')
            ->where('cq.class_id', $classId)
            ->whereIn('qa.status', ['submitted', 'expired'])
            ->selectRaw("case when qa.status = 'expired' then 'quiz_expired' else 'quiz_submitted' end as type, u.full_name as student_name, cq.title as title, qa.submitted_at as occurred_at")
            ->orderByDesc('occurred_at')
            ->limit(5)
            ->get();

        return $modules->merge($quizzes)->sortByDesc('occurred_at')->take(10)->values()->all();
    }
}
