<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Speaking\ListSpeakingAttemptsRequest;
use App\Http\Requests\Speaking\ReviewSpeakingAttemptRequest;
use App\Http\Resources\SpeakingAttemptResource;
use App\Models\SpeakingAttempt;
use App\Services\SpeakingAttemptService;
use Illuminate\Http\JsonResponse;

class TeacherSpeakingController extends Controller
{
    public function __construct(private readonly SpeakingAttemptService $attemptService) {}

    public function attempts(ListSpeakingAttemptsRequest $request): JsonResponse
    {
        $classIds = $request->user()->teacherClassAssignments()->where('is_active', true)->pluck('class_id');
        $sort = $request->validated('sort', 'created_at');
        $direction = $request->validated('direction', 'desc');
        $search = $request->validated('search');
        $attempts = SpeakingAttempt::query()
            ->with(['exercise.referenceAudio', 'student', 'reviewer'])
            ->whereHas('exercise', fn ($query) => $query
                ->where(fn ($nested) => $nested->whereIn('classroom_id', $classIds)->orWhereNull('classroom_id')))
            ->when($request->validated('analysis_status'), fn ($query, $status) => $query->where('analysis_status', $status))
            ->when($request->validated('review_status'), fn ($query, $status) => $query->where('review_status', $status))
            ->when($search, fn ($query, $value) => $query->where(fn ($nested) => $nested
                ->whereHas('student', fn ($student) => $student->where('full_name', 'ilike', "%{$value}%")->orWhere('email', 'ilike', "%{$value}%"))
                ->orWhereHas('exercise', fn ($exercise) => $exercise->where('title', 'ilike', "%{$value}%"))))
            ->orderBy($sort, $direction)
            ->orderBy('id', $direction)
            ->paginate($request->validated('per_page', 15));

        return ApiResponse::paginated('Percobaan speaking siswa berhasil diambil.', $attempts, SpeakingAttemptResource::collection($attempts->getCollection())->resolve());
    }

    public function showAttempt(SpeakingAttempt $attempt): JsonResponse
    {
        abort_unless($this->attemptService->teacherCanAccess(request()->user(), $attempt->load('exercise')), 403);

        return ApiResponse::success('Detail percobaan speaking siswa berhasil diambil.', new SpeakingAttemptResource($attempt->load(['exercise.referenceAudio', 'student', 'reviewer'])));
    }

    public function feedback(ReviewSpeakingAttemptRequest $request, SpeakingAttempt $attempt): JsonResponse
    {
        abort_unless($this->attemptService->teacherCanAccess($request->user(), $attempt->load('exercise')), 403);

        $attempt->forceFill([
            'teacher_score' => $request->validated('teacher_score'),
            'teacher_feedback' => $request->validated('teacher_feedback'),
            'reviewed_by_id' => $request->user()->id,
            'reviewed_at' => now(),
            'review_status' => 'reviewed',
        ])->save();

        return ApiResponse::success('Feedback speaking berhasil disimpan.', new SpeakingAttemptResource($attempt->refresh()->load(['exercise', 'student', 'reviewer'])));
    }
}
