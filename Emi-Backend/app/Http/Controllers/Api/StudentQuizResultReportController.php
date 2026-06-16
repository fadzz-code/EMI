<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Reports\StudentQuizResultReportRequest;
use App\Services\DashboardPeriodService;
use App\Services\QuizResultReportService;
use App\Services\ReportScopeService;
use Illuminate\Http\JsonResponse;

class StudentQuizResultReportController extends Controller
{
    public function __construct(
        private readonly QuizResultReportService $reportService,
        private readonly DashboardPeriodService $periodService,
        private readonly ReportScopeService $scopeService,
    ) {}

    public function index(StudentQuizResultReportRequest $request): JsonResponse
    {
        $this->periodService->resolve($request->validated());
        $class = $this->scopeService->requireStudentClass($request->user());
        $rows = $this->reportService->rows($request->validated(), $class->id, $request->user()->id);
        $rows->getCollection()->transform(function (array $row) {
            if (! $row['quiz']['show_result']) {
                $row['best_score_percent'] = null;
                $row['best_attempt_number'] = null;
            }

            return $row;
        });

        return response()->json([
            'success' => true,
            'message' => 'Laporan hasil kuis siswa berhasil diambil.',
            'data' => [
                'summary' => $this->reportService->summary($request->validated(), $class->id, $request->user()->id, true),
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
