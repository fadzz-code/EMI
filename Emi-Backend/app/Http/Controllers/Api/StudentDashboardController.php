<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Reports\DashboardSummaryRequest;
use App\Services\DashboardPeriodService;
use App\Services\ReportScopeService;
use App\Services\StudentDashboardService;
use Illuminate\Http\JsonResponse;

class StudentDashboardController extends Controller
{
    public function __construct(
        private readonly StudentDashboardService $dashboardService,
        private readonly DashboardPeriodService $periodService,
        private readonly ReportScopeService $scopeService,
    ) {}

    public function summary(DashboardSummaryRequest $request): JsonResponse
    {
        $this->periodService->resolve($request->validated());
        $class = $this->scopeService->studentClass($request->user());

        return ApiResponse::success('Ringkasan dashboard Siswa berhasil diambil.', $this->dashboardService->summary($request->user(), $class));
    }
}
