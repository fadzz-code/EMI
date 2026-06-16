<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Reports\AdminClassProgressReportRequest;
use App\Http\Requests\Reports\AdminSchoolProgressReportRequest;
use App\Http\Requests\Reports\StudentProgressReportRequest;
use App\Services\DashboardPeriodService;
use App\Services\LearningProgressReportService;
use App\Services\ReportScopeService;
use Illuminate\Http\JsonResponse;

class AdminProgressReportController extends Controller
{
    public function __construct(
        private readonly LearningProgressReportService $reportService,
        private readonly DashboardPeriodService $periodService,
        private readonly ReportScopeService $scopeService,
    ) {}

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
}
