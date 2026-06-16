<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Reports\QuizResultReportRequest;
use App\Services\DashboardPeriodService;
use App\Services\QuizResultReportService;
use App\Services\ReportScopeService;
use Illuminate\Http\JsonResponse;

class TeacherQuizResultReportController extends Controller
{
    public function __construct(
        private readonly QuizResultReportService $reportService,
        private readonly DashboardPeriodService $periodService,
        private readonly ReportScopeService $scopeService,
    ) {}

    public function index(QuizResultReportRequest $request): JsonResponse
    {
        $this->periodService->resolve($request->validated());
        $class = $this->scopeService->assertTeacherFilters($request->user(), $request->validated());
        $rows = $this->reportService->rows($request->validated(), $class->id);

        return response()->json([
            'success' => true,
            'message' => 'Laporan hasil kuis kelas berhasil diambil.',
            'data' => [
                'summary' => $this->reportService->summary($request->validated(), $class->id),
                'rows' => $rows->getCollection()->all(),
            ],
            'meta' => [
                'current_page' => $rows->currentPage(),
                'per_page' => $rows->perPage(),
                'total' => $rows->total(),
                'last_page' => $rows->lastPage(),
            ],
        ]);
    }
}
