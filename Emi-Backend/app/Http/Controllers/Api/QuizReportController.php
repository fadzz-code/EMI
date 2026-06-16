<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Resources\QuizReportResource;
use App\Models\ClassQuiz;
use App\Services\QuizReportService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;

class QuizReportController extends Controller
{
    public function __construct(private readonly QuizReportService $service) {}

    public function show(string $quizId): JsonResponse
    {
        $quiz = ClassQuiz::query()->findOrFail($quizId);
        Gate::authorize('report', $quiz);

        return ApiResponse::success('Laporan kuis berhasil diambil.', new QuizReportResource($this->service->summary($quiz)));
    }
}
