<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\ApiException;
use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Reports\StudentProgressReportRequest;
use App\Services\DashboardPeriodService;
use App\Services\LearningProgressReportService;
use App\Services\ReportScopeService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class StudentProgressReportController extends Controller
{
    public function __construct(
        private readonly LearningProgressReportService $reportService,
        private readonly DashboardPeriodService $periodService,
        private readonly ReportScopeService $scopeService,
    ) {}

    public function show(StudentProgressReportRequest $request): JsonResponse
    {
        $this->periodService->resolve($request->validated());
        if ($request->filled('student_id') || $request->filled('school_id') || $request->filled('class_id')) {
            throw new ApiException('Scope laporan siswa berasal dari token login.', 'REPORT_SCOPE_FORBIDDEN', 403);
        }
        $class = $this->scopeService->requireStudentClass($request->user());
        $summary = $this->reportService->studentRows([], $class->id, $request->user()->id, false)->first();
        $modules = DB::table('class_modules as cm')
            ->leftJoin('module_progress as mp', fn ($join) => $join->on('mp.class_module_id', '=', 'cm.id')->where('mp.student_id', $request->user()->id))
            ->where('cm.class_id', $class->id)
            ->where('cm.status', 'published')
            ->whereNull('cm.deleted_at')
            ->orderBy('cm.sort_order')
            ->paginate(min((int) ($request->validated('per_page') ?? config('dashboard.default_per_page')), (int) config('dashboard.max_per_page')), [
                'cm.id',
                'cm.title',
                'cm.sort_order',
                DB::raw("coalesce(mp.status, 'not_started') as status"),
                DB::raw('coalesce(mp.progress_percent, 0) as progress_percent'),
                'mp.completed_lessons',
                'mp.total_lessons',
                'mp.last_calculated_at',
            ]);

        return ApiResponse::success('Laporan progress siswa berhasil diambil.', [
            'summary' => $summary,
            'modules' => [
                'data' => $modules->items(),
                'meta' => [
                    'current_page' => $modules->currentPage(),
                    'per_page' => $modules->perPage(),
                    'total' => $modules->total(),
                    'last_page' => $modules->lastPage(),
                ],
            ],
        ]);
    }
}
