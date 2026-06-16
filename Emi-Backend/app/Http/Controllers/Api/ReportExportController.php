<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Reports\AdminClassProgressReportRequest;
use App\Http\Requests\Reports\AdminSchoolProgressReportRequest;
use App\Http\Requests\Reports\QuizResultReportRequest;
use App\Http\Requests\Reports\StudentProgressReportRequest;
use App\Models\AuditLog;
use App\Services\AuditLogService;
use App\Services\CsvReportExportService;
use App\Services\DashboardPeriodService;
use App\Services\LearningProgressReportService;
use App\Services\QuizResultReportService;
use App\Services\ReportScopeService;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ReportExportController extends Controller
{
    public function __construct(
        private readonly CsvReportExportService $csv,
        private readonly LearningProgressReportService $learningReports,
        private readonly QuizResultReportService $quizReports,
        private readonly DashboardPeriodService $periodService,
        private readonly ReportScopeService $scopeService,
        private readonly AuditLogService $auditLogService,
    ) {}

    public function adminSchools(AdminSchoolProgressReportRequest $request): StreamedResponse
    {
        $period = $this->periodService->resolve($request->validated());
        $rows = $this->learningReports->schoolRows($request->validated(), false);
        $this->audit($request, 'report.progress_exported', 'schools', $period, $rows->count());

        return $this->csv->stream('laporan-progress-sekolah-'.now('UTC')->toDateString().'.csv', [
            'Sekolah', 'Kelas Aktif', 'Siswa Aktif', 'Modul Terbit', 'Progress Belajar (%)', 'Completion Modul (%)', 'Kuis Terbit', 'Partisipasi Kuis (%)', 'Rata-rata Nilai Kuis (%)',
        ], $rows, fn ($row) => [
            $row->school_name,
            $row->active_classes,
            $row->active_students,
            $row->published_modules,
            $row->average_learning_progress_percent,
            $row->module_completion_rate_percent,
            $row->published_quizzes,
            $row->quiz_participation_rate_percent,
            $row->average_quiz_score_percent,
        ]);
    }

    public function adminClasses(AdminClassProgressReportRequest $request): StreamedResponse
    {
        $period = $this->periodService->resolve($request->validated());
        $this->scopeService->assertAdminScope($request->validated());
        $rows = $this->learningReports->classRows($request->validated(), false);
        $this->audit($request, 'report.progress_exported', 'classes', $period, $rows->count());

        return $this->csv->stream('laporan-progress-kelas-'.now('UTC')->toDateString().'.csv', [
            'Sekolah', 'Kelas', 'Siswa Aktif', 'Modul Terbit', 'Progress Belajar (%)', 'Modul Selesai', 'Kuis Terbit', 'Siswa Ikut Kuis', 'Rata-rata Nilai Kuis (%)',
        ], $rows, fn ($row) => [
            $row->school_name,
            $row->class_name,
            $row->active_students,
            $row->published_modules,
            $row->average_learning_progress_percent,
            $row->completed_module_count,
            $row->published_quizzes,
            $row->students_participated_in_quiz,
            $row->average_quiz_score_percent,
        ]);
    }

    public function adminStudents(StudentProgressReportRequest $request): StreamedResponse
    {
        $period = $this->periodService->resolve($request->validated());
        $this->scopeService->assertAdminScope($request->validated());
        $rows = $this->learningReports->studentRows($request->validated(), null, null, false);
        $this->audit($request, 'report.progress_exported', 'students', $period, $rows->count());

        return $this->studentCsv($rows, 'laporan-progress-siswa-'.now('UTC')->toDateString().'.csv');
    }

    public function teacherStudents(StudentProgressReportRequest $request): StreamedResponse
    {
        $period = $this->periodService->resolve($request->validated());
        $class = $this->scopeService->assertTeacherFilters($request->user(), $request->validated());
        $rows = $this->learningReports->studentRows($request->validated(), $class->id, null, false);
        $this->audit($request, 'report.progress_exported', 'teacher-students', $period, $rows->count());

        return $this->studentCsv($rows, 'laporan-progress-siswa-kelas-'.now('UTC')->toDateString().'.csv');
    }

    public function adminQuizResults(QuizResultReportRequest $request): StreamedResponse
    {
        $period = $this->periodService->resolve($request->validated());
        $this->scopeService->assertAdminScope($request->validated());
        $rows = $this->quizReports->rows($request->validated(), null, null, false);
        $this->audit($request, 'report.quiz_results_exported', 'admin-quiz-results', $period, $rows->count());

        return $this->quizCsv($rows, 'laporan-hasil-kuis-'.now('UTC')->toDateString().'.csv');
    }

    public function teacherQuizResults(QuizResultReportRequest $request): StreamedResponse
    {
        $period = $this->periodService->resolve($request->validated());
        $class = $this->scopeService->assertTeacherFilters($request->user(), $request->validated());
        $rows = $this->quizReports->rows($request->validated(), $class->id, null, false);
        $this->audit($request, 'report.quiz_results_exported', 'teacher-quiz-results', $period, $rows->count());

        return $this->quizCsv($rows, 'laporan-hasil-kuis-kelas-'.now('UTC')->toDateString().'.csv');
    }

    private function studentCsv(iterable $rows, string $filename): StreamedResponse
    {
        return $this->csv->stream($filename, [
            'Nama Siswa', 'Sekolah', 'Kelas', 'Modul Terbit', 'Modul Selesai', 'Progress Belajar (%)', 'Kuis Terbit', 'Kuis Dicoba', 'Kuis Selesai', 'Rata-rata Nilai Kuis (%)', 'Aktivitas Belajar Terakhir',
        ], $rows, fn (array $row) => [
            $row['full_name'],
            $row['school']['name'],
            $row['class']['name'],
            $row['published_modules'],
            $row['completed_modules'],
            $row['overall_learning_progress_percent'],
            $row['published_quizzes'],
            $row['quizzes_attempted'],
            $row['quizzes_completed'],
            $row['average_best_quiz_score_percent'],
            $row['last_learning_activity_at'],
        ]);
    }

    private function quizCsv(iterable $rows, string $filename): StreamedResponse
    {
        return $this->csv->stream($filename, [
            'Sekolah', 'Kelas', 'Kuis', 'Nama Siswa', 'Jumlah Attempt', 'Attempt Terbaik', 'Nilai Terbaik (%)', 'Status Terakhir', 'Submit Terakhir',
        ], $rows, fn (array $row) => [
            $row['school']['name'],
            $row['class']['name'],
            $row['quiz']['title'],
            $row['student']['full_name'],
            $row['attempt_count'],
            $row['best_attempt_number'],
            $row['best_score_percent'],
            $row['latest_status'],
            $row['latest_submitted_at'],
        ]);
    }

    private function audit($request, string $action, string $reportType, array $period, int $rowCount): void
    {
        $this->auditLogService->record($action, new AuditLog, $request->user(), null, null, [
            'report_type' => $reportType,
            'date_from' => $period['date_from'],
            'date_to' => $period['date_to'],
            'row_count' => $rowCount,
            'format' => 'csv',
        ], $request);
    }
}
