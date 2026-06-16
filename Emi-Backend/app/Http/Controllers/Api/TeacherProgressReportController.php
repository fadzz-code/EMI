<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Reports\StudentProgressReportRequest;
use App\Services\DashboardPeriodService;
use App\Services\LearningProgressReportService;
use App\Services\ReportScopeService;
use Illuminate\Http\JsonResponse;

class TeacherProgressReportController extends Controller
{
    public function __construct(
        private readonly LearningProgressReportService $reportService,
        private readonly DashboardPeriodService $periodService,
        private readonly ReportScopeService $scopeService,
    ) {}

    public function students(StudentProgressReportRequest $request): JsonResponse
    {
        $this->periodService->resolve($request->validated());
        $class = $this->scopeService->assertTeacherFilters($request->user(), $request->validated());
        $rows = $this->reportService->studentRows($request->validated(), $class->id);

        return ApiResponse::paginated('Laporan progress siswa kelas berhasil diambil.', $rows, $rows->getCollection()->all());
    }
}
