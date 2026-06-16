<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Reports\DashboardSummaryRequest;
use App\Services\DashboardPeriodService;
use App\Services\ReportScopeService;
use App\Services\TeacherDashboardService;
use Illuminate\Http\JsonResponse;

class TeacherDashboardController extends Controller
{
    public function __construct(
        private readonly TeacherDashboardService $dashboardService,
        private readonly DashboardPeriodService $periodService,
        private readonly ReportScopeService $scopeService,
    ) {}

    public function summary(DashboardSummaryRequest $request): JsonResponse
    {
        $this->periodService->resolve($request->validated());
        $class = $this->scopeService->teacherClass($request->user());

        return ApiResponse::success('Ringkasan dashboard Guru berhasil diambil.', $this->dashboardService->summary($class));
    }
}
