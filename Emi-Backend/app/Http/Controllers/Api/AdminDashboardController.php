<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Reports\DashboardSummaryRequest;
use App\Services\AdminDashboardService;
use App\Services\DashboardPeriodService;
use App\Services\ReportScopeService;
use Illuminate\Http\JsonResponse;

class AdminDashboardController extends Controller
{
    public function __construct(
        private readonly AdminDashboardService $dashboardService,
        private readonly DashboardPeriodService $periodService,
        private readonly ReportScopeService $scopeService,
    ) {}

    public function summary(DashboardSummaryRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $period = $this->periodService->resolve($validated);
        $scope = $this->scopeService->assertAdminScope($validated);

        return ApiResponse::success('Ringkasan dashboard Admin berhasil diambil.', $this->dashboardService->summary($period, $scope));
    }
}
