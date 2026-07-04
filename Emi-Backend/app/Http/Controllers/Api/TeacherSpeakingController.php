<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Speaking\ReviewSpeakingAttemptRequest;
use App\Http\Resources\SpeakingAttemptResource;
use App\Models\SpeakingAttempt;
use App\Services\SpeakingAttemptService;
use Illuminate\Http\JsonResponse;

class TeacherSpeakingController extends Controller
{
    public function __construct(private readonly SpeakingAttemptService $attemptService) {}

    public function attempts(): JsonResponse
    {
        $classIds = request()->user()->teacherClassAssignments()->where('is_active', true)->pluck('class_id');
        $attempts = SpeakingAttempt::query()
            ->with(['exercise', 'student'])
            ->whereHas('exercise', fn ($query) => $query->whereIn('classroom_id', $classIds))
            ->latest()
            ->get();

        return ApiResponse::success('Percobaan speaking siswa berhasil diambil.', SpeakingAttemptResource::collection($attempts)->resolve());
    }

    public function showAttempt(SpeakingAttempt $attempt): JsonResponse
    {
        abort_unless($this->attemptService->teacherCanAccess(request()->user(), $attempt->load('exercise')), 403);

        return ApiResponse::success('Detail percobaan speaking siswa berhasil diambil.', new SpeakingAttemptResource($attempt->load(['exercise', 'student'])));
    }

    public function feedback(ReviewSpeakingAttemptRequest $request, SpeakingAttempt $attempt): JsonResponse
    {
        abort_unless($this->attemptService->teacherCanAccess($request->user(), $attempt->load('exercise')), 403);

        $attempt->forceFill([
            'teacher_score' => $request->validated('teacher_score'),
            'teacher_feedback' => $request->validated('teacher_feedback'),
            'reviewed_by_id' => $request->user()->id,
            'reviewed_at' => now(),
            'status' => 'reviewed',
        ])->save();

        return ApiResponse::success('Feedback speaking berhasil disimpan.', new SpeakingAttemptResource($attempt->refresh()->load(['exercise', 'student'])));
    }
}
