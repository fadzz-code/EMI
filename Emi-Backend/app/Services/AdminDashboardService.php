<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;

class AdminDashboardService
{
    public function __construct(
        private readonly LearningProgressReportService $learningReports,
        private readonly QuizResultReportService $quizReports,
        private readonly DashboardTrendService $trendService,
    ) {}

    public function summary(array $period, array $scope): array
    {
        $schoolId = $scope['school_id'] ?? null;
        $classId = $scope['class_id'] ?? null;
        $quizSummary = $this->quizReports->summary(['school_id' => $schoolId, 'class_id' => $classId]);

        return [
            'overview' => [
                'active_schools' => $this->activeSchools($schoolId),
                'active_classes' => $this->activeClasses($schoolId, $classId),
                'active_teachers' => $this->activeUsers('teacher', $schoolId, $classId),
                'active_students' => $this->activeUsers('student', $schoolId, $classId),
                'pending_registration_requests' => $this->pendingRegistrations($schoolId, $classId),
            ],
            'content' => [
                'active_dictionary_entries' => DB::table('dictionary_entries')->where('status', 'active')->whereNull('deleted_at')->count(),
                'published_module_templates' => DB::table('module_templates')->where('status', 'published')->whereNull('deleted_at')->count(),
                'published_class_modules' => $this->publishedClassContent('class_modules', $schoolId, $classId),
                'published_quiz_templates' => DB::table('quiz_templates')->where('status', 'published')->whereNull('deleted_at')->count(),
                'published_class_quizzes' => $this->publishedClassContent('class_quizzes', $schoolId, $classId),
            ],
            'learning' => [
                'students_with_learning_activity' => $this->studentsWithLearningActivity($period, $schoolId, $classId),
                'completed_modules' => $this->completedModules($period, $schoolId, $classId),
                'average_learning_progress_percent' => $this->learningReports->averageProgress($schoolId, $classId),
            ],
            'quizzes' => [
                'final_attempts' => $quizSummary['submitted_attempts'] + $quizSummary['expired_attempts'],
                'submitted_attempts' => $quizSummary['submitted_attempts'],
                'expired_attempts' => $quizSummary['expired_attempts'],
                'in_progress_attempts' => $quizSummary['in_progress_attempts'],
                'average_score_percent' => $quizSummary['average_best_score_percent'],
                'participation_rate_percent' => $quizSummary['participation_rate_percent'],
            ],
            'trends' => $this->trendService->trends($period, $schoolId, $classId),
            'capabilities' => ['speaking_reports' => false],
            'speaking_summary' => null,
            'generated_at' => now('UTC')->toISOString(),
        ];
    }

    private function activeSchools(?string $schoolId): int
    {
        return DB::table('schools')->where('status', 'active')->when($schoolId, fn ($query) => $query->where('id', $schoolId))->count();
    }

    private function activeClasses(?string $schoolId, ?string $classId): int
    {
        return DB::table('classes as c')
            ->join('schools as s', 's.id', '=', 'c.school_id')
            ->where('c.status', 'active')
            ->where('s.status', 'active')
            ->when($schoolId, fn ($query) => $query->where('s.id', $schoolId))
            ->when($classId, fn ($query) => $query->where('c.id', $classId))
            ->count();
    }

    private function activeUsers(string $role, ?string $schoolId, ?string $classId): int
    {
        $pivot = $role === 'teacher' ? 'teacher_class_assignments' : 'student_class_memberships';
        $userKey = $role === 'teacher' ? 'teacher_id' : 'student_id';

        return DB::table('users as u')
            ->join("{$pivot} as p", "p.{$userKey}", '=', 'u.id')
            ->join('classes as c', 'c.id', '=', 'p.class_id')
            ->join('schools as s', 's.id', '=', 'c.school_id')
            ->where('u.role', $role)
            ->where('u.status', 'approved')
            ->where('p.is_active', true)
            ->where('c.status', 'active')
            ->where('s.status', 'active')
            ->when($schoolId, fn ($query) => $query->where('s.id', $schoolId))
            ->when($classId, fn ($query) => $query->where('c.id', $classId))
            ->distinct('u.id')
            ->count('u.id');
    }

    private function pendingRegistrations(?string $schoolId, ?string $classId): int
    {
        return DB::table('registration_requests')
            ->where('status', 'pending')
            ->when($schoolId, fn ($query) => $query->where('school_id', $schoolId))
            ->when($classId, fn ($query) => $query->where('class_id', $classId))
            ->count();
    }

    private function publishedClassContent(string $table, ?string $schoolId, ?string $classId): int
    {
        return DB::table("{$table} as content")
            ->join('classes as c', 'c.id', '=', 'content.class_id')
            ->join('schools as s', 's.id', '=', 'c.school_id')
            ->where('content.status', 'published')
            ->whereNull('content.deleted_at')
            ->where('c.status', 'active')
            ->where('s.status', 'active')
            ->when($schoolId, fn ($query) => $query->where('s.id', $schoolId))
            ->when($classId, fn ($query) => $query->where('c.id', $classId))
            ->count();
    }

    private function studentsWithLearningActivity(array $period, ?string $schoolId, ?string $classId): int
    {
        return DB::table('module_progress as mp')
            ->join('class_modules as cm', 'cm.id', '=', 'mp.class_module_id')
            ->join('classes as c', 'c.id', '=', 'cm.class_id')
            ->whereBetween('mp.updated_at', [$period['from'], $period['to']])
            ->when($schoolId, fn ($query) => $query->where('c.school_id', $schoolId))
            ->when($classId, fn ($query) => $query->where('c.id', $classId))
            ->distinct('mp.student_id')
            ->count('mp.student_id');
    }

    private function completedModules(array $period, ?string $schoolId, ?string $classId): int
    {
        return DB::table('module_progress as mp')
            ->join('class_modules as cm', 'cm.id', '=', 'mp.class_module_id')
            ->join('classes as c', 'c.id', '=', 'cm.class_id')
            ->where('mp.status', 'completed')
            ->whereBetween('mp.completed_at', [$period['from'], $period['to']])
            ->when($schoolId, fn ($query) => $query->where('c.school_id', $schoolId))
            ->when($classId, fn ($query) => $query->where('c.id', $classId))
            ->count();
    }
}
