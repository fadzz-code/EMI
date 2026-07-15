<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Reports\AdminClassProgressReportRequest;
use App\Http\Requests\Reports\AdminProgressOverviewRequest;
use App\Http\Requests\Reports\AdminSchoolProgressReportRequest;
use App\Http\Requests\Reports\StudentProgressReportRequest;
use App\Models\AuditLog;
use App\Models\SchoolClass;
use App\Models\User;
use App\Services\AuditLogService;
use App\Services\DashboardPeriodService;
use App\Services\LearningProgressReportService;
use App\Services\QuizResultReportService;
use App\Services\ReportScopeService;
use App\Services\SimplePdfService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;

class AdminProgressReportController extends Controller
{
    public function __construct(
        private readonly LearningProgressReportService $reportService,
        private readonly QuizResultReportService $quizService,
        private readonly DashboardPeriodService $periodService,
        private readonly ReportScopeService $scopeService,
        private readonly SimplePdfService $pdfService,
        private readonly AuditLogService $auditLogService,
    ) {}

    public function overview(AdminProgressOverviewRequest $request): JsonResponse
    {
        $filters = $request->validated();
        $this->periodService->resolve($filters);
        $this->scopeService->assertAdminScope($filters);
        $students = $this->reportService->studentRows(array_merge($filters, ['page' => $filters['student_page'] ?? 1, 'per_page' => $filters['student_per_page'] ?? config('dashboard.default_per_page'), '_page_name' => 'student_page']));
        $classes = $this->reportService->classRows(array_merge($filters, ['page' => $filters['class_page'] ?? 1, 'per_page' => $filters['class_per_page'] ?? config('dashboard.default_per_page')]));

        return ApiResponse::success('Overview progress berhasil diambil.', [
            'summary' => $this->reportService->overviewSummary($filters),
            'students' => $this->page($students),
            'classes' => $this->page($classes),
            'capabilities' => ['speaking_reports' => false],
        ]);
    }

    public function student(StudentProgressReportRequest $request, User $student): JsonResponse
    {
        abort_unless($student->role === 'student', 404);
        $filters = $request->validated();
        $this->periodService->resolve($filters);
        $progress = $this->reportService->studentRows($filters, null, $student->id, false)->first();
        abort_unless($progress, 404);
        $quizFilters = array_merge($filters, ['page' => $filters['quiz_page'] ?? 1, 'per_page' => $filters['quiz_per_page'] ?? config('dashboard.default_per_page')]);
        $quizzes = $this->quizService->rows($quizFilters, null, $student->id);

        return ApiResponse::success('Detail progress siswa berhasil diambil.', [
            'student' => ['id' => $student->id, 'full_name' => $student->full_name, 'email' => $student->email, 'status' => $student->status],
            'progress' => $progress,
            'quizzes' => $this->page($quizzes),
            'quiz_summary' => $this->quizService->summary($quizFilters, null, $student->id),
            'capabilities' => ['speaking_reports' => false],
        ]);
    }

    public function class(AdminClassProgressReportRequest $request, SchoolClass $class): JsonResponse
    {
        $filters = array_merge($request->validated(), ['class_id' => $class->id]);
        $this->periodService->resolve($filters);
        $students = $this->reportService->studentRows($filters);
        $teacher = DB::table('teacher_class_assignments as tca')->join('users as u', 'u.id', '=', 'tca.teacher_id')->where('tca.class_id', $class->id)->where('tca.is_active', true)->select('u.id', 'u.full_name', 'u.email')->first();
        $metrics = DB::query()->fromSub($this->reportService->studentMetricQuery($filters)->where('c.id', $class->id), 'students')->selectRaw("count(*)::int as active_students, round(coalesce(avg(overall_learning_progress_percent), 0)::numeric, 2) as average_module_progress_percent, round(avg(average_best_quiz_score_percent) filter (where average_best_quiz_score_percent is not null)::numeric, 2) as average_best_final_quiz_score_percent, max(greatest(coalesce(last_learning_activity_at, '-infinity'::timestamp), coalesce(last_quiz_activity_at, '-infinity'::timestamp))) as last_activity_at, sum(case when published_modules > 0 and completed_modules = published_modules then 1 else 0 end)::int as completed_students, sum(case when started_modules = 0 then 1 else 0 end)::int as not_started_students")->first();
        $class->load('school');

        return ApiResponse::success('Detail progress kelas berhasil diambil.', [
            'class' => ['id' => $class->id, 'name' => $class->name, 'academic_year' => $class->academic_year, 'status' => $class->status, 'school' => ['id' => $class->school->id, 'name' => $class->school->name], 'teacher' => $teacher],
            'summary' => ['active_students' => (int) ($metrics?->active_students ?? 0), 'average_module_progress_percent' => (float) ($metrics?->average_module_progress_percent ?? 0), 'average_best_final_quiz_score_percent' => $metrics?->average_best_final_quiz_score_percent !== null ? (float) $metrics->average_best_final_quiz_score_percent : null, 'last_activity_at' => $metrics?->last_activity_at, 'completed_students' => (int) ($metrics?->completed_students ?? 0), 'not_started_students' => (int) ($metrics?->not_started_students ?? 0)],
            'students' => $this->page($students),
            'capabilities' => ['speaking_reports' => false],
        ]);
    }

    public function pdf(AdminProgressOverviewRequest $request): Response
    {
        $filters = $request->validated();
        $period = $this->periodService->resolve($filters);
        $this->scopeService->assertAdminScope($filters);
        $rows = $this->reportService->studentRows($filters, null, null, false);
        $summary = $this->reportService->overviewSummary($filters);
        $report = [
            'title' => 'Laporan Progress Siswa',
            'sections' => [
                ['title' => 'Filter Laporan', 'items' => $this->filterItems($filters, $period)],
                ['title' => 'Ringkasan', 'items' => ['Siswa aktif' => $summary['active_students'], 'Rata-rata progress modul' => $this->percent($summary['average_module_progress_percent']), 'Rata-rata nilai kuis' => $this->percent($summary['average_best_final_quiz_score_percent']), 'Speaking' => 'Belum tersedia']],
                ['title' => 'Tabel Progress Siswa', 'headers' => ['No', 'Nama siswa', 'Email', 'Sekolah', 'Kelas', 'Progress', 'Nilai kuis', 'Kuis', 'Status', 'Aktivitas terakhir'], 'widths' => [22, 67, 78, 55, 50, 45, 45, 35, 50, 64], 'rows' => $rows->values()->map(fn (array $row, int $index) => [$index + 1, $row['full_name'], $row['email'], $row['school']['name'], $row['class']['name'], $this->percent($row['overall_learning_progress_percent']), $this->percent($row['average_best_quiz_score_percent']), $row['quizzes_completed'].'/'.$row['published_quizzes'], $this->status($row['learning_status']), $this->activity($row)])->all()],
                ['title' => 'Speaking', 'note' => 'Laporan speaking belum tersedia.'],
            ],
        ];
        $this->auditPdf($request, 'report.admin_progress_pdf_exported', 'admin_progress', $period, count($rows));

        return $this->pdfResponse($report, 'laporan-progress-siswa.pdf');
    }

    public function studentPdf(StudentProgressReportRequest $request, User $student): Response
    {
        abort_unless($student->role === 'student', 404);
        $filters = $request->validated();
        $period = $this->periodService->resolve($filters);
        $row = $this->reportService->studentRows($filters, null, $student->id, false)->first();
        abort_unless($row, 404);
        $quizzes = $this->quizService->rows($filters, null, $student->id, false);
        $report = [
            'title' => 'Laporan Progress Siswa',
            'sections' => [
                ['title' => 'Identitas Siswa', 'items' => ['Nama' => $student->full_name, 'Email' => $student->email, 'Sekolah' => $row['school']['name'], 'Kelas' => $row['class']['name'], 'Status akun' => $this->status($student->status), 'Status belajar' => $this->status($row['learning_status'])]],
                ['title' => 'Ringkasan Progress', 'items' => ['Progress modul' => $this->percent($row['overall_learning_progress_percent']), 'Modul selesai' => $row['completed_modules'].'/'.$row['published_modules'], 'Pelajaran selesai' => $row['completed_lessons'].'/'.$row['total_published_lessons'], 'Rata-rata nilai kuis' => $this->percent($row['average_best_quiz_score_percent']), 'Kuis selesai' => $row['quizzes_completed'].'/'.$row['published_quizzes'], 'Aktivitas terakhir' => $this->activity($row)]],
                ['title' => 'Riwayat Kuis', 'headers' => ['No', 'Kuis', 'Attempt', 'Nilai terbaik', 'Status terakhir', 'Submit terakhir'], 'widths' => [25, 170, 70, 75, 80, 91], 'rows' => $quizzes->values()->map(fn (array $quiz, int $index) => [$index + 1, $quiz['quiz']['title'], $quiz['attempt_count'].($quiz['best_attempt_number'] ? ', terbaik #'.$quiz['best_attempt_number'] : ''), $this->percent($quiz['best_score_percent']), $this->status($quiz['latest_status']), $quiz['latest_submitted_at'] ?: '-'])->all()],
                ['title' => 'Speaking', 'note' => 'Laporan speaking belum tersedia.'],
            ],
        ];
        $this->auditPdf($request, 'report.admin_student_progress_pdf_exported', 'student_progress', $period, 1);

        return $this->pdfResponse($report, 'progress-siswa-'.$this->slug($student->full_name).'.pdf');
    }

    public function classPdf(AdminClassProgressReportRequest $request, SchoolClass $class): Response
    {
        $filters = array_merge($request->validated(), ['class_id' => $class->id]);
        $period = $this->periodService->resolve($filters);
        $rows = $this->reportService->studentRows($filters, null, null, false);
        $summary = $this->reportService->overviewSummary($filters);
        $teacher = DB::table('teacher_class_assignments as tca')->join('users as u', 'u.id', '=', 'tca.teacher_id')->where('tca.class_id', $class->id)->where('tca.is_active', true)->value('u.full_name');
        $class->load('school');
        $report = [
            'title' => 'Laporan Progress Kelas',
            'sections' => [
                ['title' => 'Identitas Kelas', 'items' => ['Nama kelas' => $class->name, 'Sekolah' => $class->school->name, 'Tahun ajaran' => $class->academic_year, 'Guru' => $teacher, 'Jumlah siswa' => count($rows)]],
                ['title' => 'Ringkasan Progress Kelas', 'items' => ['Rata-rata progress modul' => $this->percent($summary['average_module_progress_percent']), 'Rata-rata nilai kuis' => $this->percent($summary['average_best_final_quiz_score_percent']), 'Siswa selesai modul' => $rows->where('learning_status', 'completed')->count(), 'Siswa belum mulai' => $rows->where('learning_status', 'not_started')->count()]],
                ['title' => 'Tabel Siswa', 'headers' => ['No', 'Nama siswa', 'Progress modul', 'Nilai kuis', 'Kuis selesai', 'Status belajar'], 'widths' => [30, 176, 80, 75, 70, 80], 'rows' => $rows->values()->map(fn (array $row, int $index) => [$index + 1, $row['full_name'], $this->percent($row['overall_learning_progress_percent']), $this->percent($row['average_best_quiz_score_percent']), $row['quizzes_completed'].'/'.$row['published_quizzes'], $this->status($row['learning_status'])])->all()],
                ['title' => 'Speaking', 'note' => 'Laporan speaking belum tersedia.'],
            ],
        ];
        $this->auditPdf($request, 'report.admin_class_progress_pdf_exported', 'class_progress', $period, count($rows));

        return $this->pdfResponse($report, 'progress-kelas-'.$this->slug($class->name).'.pdf');
    }

    public function schools(AdminSchoolProgressReportRequest $request): JsonResponse
    {
        $this->periodService->resolve($request->validated());
        $rows = $this->reportService->schoolRows($request->validated());

        return ApiResponse::paginated('Laporan progress sekolah berhasil diambil.', $rows, $rows->getCollection()->all());
    }

    public function classes(AdminClassProgressReportRequest $request): JsonResponse
    {
        $this->periodService->resolve($request->validated());
        $this->scopeService->assertAdminScope($request->validated());
        $rows = $this->reportService->classRows($request->validated());

        return ApiResponse::paginated('Laporan progress kelas berhasil diambil.', $rows, $rows->getCollection()->all());
    }

    public function students(StudentProgressReportRequest $request): JsonResponse
    {
        $this->periodService->resolve($request->validated());
        $this->scopeService->assertAdminScope($request->validated());
        $rows = $this->reportService->studentRows($request->validated());

        return ApiResponse::paginated('Laporan progress siswa berhasil diambil.', $rows, $rows->getCollection()->all());
    }

    private function page($paginator): array
    {
        return ['data' => $paginator->items(), 'meta' => ['current_page' => $paginator->currentPage(), 'per_page' => $paginator->perPage(), 'total' => $paginator->total(), 'last_page' => $paginator->lastPage()]];
    }

    private function pdfResponse(array $report, string $filename): Response
    {
        return response($this->pdfService->make($report), 200, ['Content-Type' => 'application/pdf', 'Content-Disposition' => 'attachment; filename="'.$filename.'"', 'Cache-Control' => 'no-store, private']);
    }

    private function filterItems(array $filters, array $period): array
    {
        return ['Periode' => $period['date_from'].' sampai '.$period['date_to'], 'Sekolah' => isset($filters['school_id']) ? 'Dipilih' : 'Semua', 'Kelas' => isset($filters['class_id']) ? 'Dipilih' : 'Semua', 'Pencarian' => $filters['search'] ?? 'Semua', 'Status belajar' => $this->status($filters['learning_status'] ?? null), 'Status kuis' => $this->status($filters['quiz_status'] ?? null)];
    }

    private function percent(mixed $value): string
    {
        return $value === null ? '-' : rtrim(rtrim(number_format((float) $value, 2, ',', '.'), '0'), ',').'%';
    }

    private function status(?string $status): string
    {
        return match ($status) {
            'not_started' => 'Belum mulai',
            'in_progress' => 'Sedang berjalan',
            'completed' => 'Selesai',
            'submitted' => 'Dikirim',
            'expired' => 'Kedaluwarsa',
            'approved' => 'Aktif',
            null, '' => '-',
            default => ucfirst(str_replace('_', ' ', $status)),
        };
    }

    private function activity(array $row): string
    {
        $values = array_filter([$row['last_learning_activity_at'] ?? null, $row['last_quiz_activity_at'] ?? null]);

        return $values === [] ? '-' : (string) max($values);
    }

    private function slug(string $value): string
    {
        $slug = trim(strtolower((string) preg_replace('/[^A-Za-z0-9]+/', '-', $value)), '-');

        return substr($slug ?: 'laporan', 0, 80);
    }

    private function auditPdf(Request $request, string $action, string $reportType, array $period, int $rowCount): void
    {
        $this->auditLogService->record($action, new AuditLog, $request->user(), null, null, ['report_type' => $reportType, 'date_from' => $period['date_from'], 'date_to' => $period['date_to'], 'row_count' => $rowCount, 'format' => 'pdf'], $request);
    }
}
