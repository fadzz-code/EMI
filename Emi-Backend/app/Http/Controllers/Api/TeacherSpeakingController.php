<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Speaking\ListSpeakingAttemptsRequest;
use App\Http\Requests\Speaking\ReviewSpeakingAttemptRequest;
use App\Http\Resources\SpeakingAttemptResource;
use App\Models\SpeakingAttempt;
use App\Services\SpeakingAttemptService;
use App\Services\SpeakingAuthorizationService;
use Illuminate\Http\JsonResponse;

class TeacherSpeakingController extends Controller
{
    public function __construct(
        private readonly SpeakingAttemptService $attemptService,
        private readonly SpeakingAuthorizationService $authorizationService,
    ) {}

    public function attempts(ListSpeakingAttemptsRequest $request): JsonResponse
    {
        $sort = $request->validated('sort', 'created_at');
        $direction = $request->validated('direction', 'desc');
        $search = $request->validated('search');
        $query = $this->authorizationService->teacherAttemptQuery($request->user())
            ->when($search, fn ($query, $value) => $query->where(fn ($nested) => $nested
                ->whereHas('student', fn ($student) => $student->where('full_name', 'ilike', "%{$value}%")->orWhere('email', 'ilike', "%{$value}%"))
                ->orWhereHas('exercise', fn ($exercise) => $exercise->where('title', 'ilike', "%{$value}%"))));
        $counts = [
            'total' => (clone $query)->count(),
            'pending' => (clone $query)->where('review_status', 'pending')->count(),
            'reviewed' => (clone $query)->where('review_status', 'reviewed')->count(),
            'failed' => (clone $query)->where('analysis_status', 'failed')->count(),
        ];
        $attempts = $query
            ->with(['exercise.referenceAudio', 'student', 'reviewer'])
            ->when($request->validated('analysis_status'), fn ($query, $status) => $query->where('analysis_status', $status))
            ->when($request->validated('review_status'), fn ($query, $status) => $query->where('review_status', $status))
            ->orderBy($sort, $direction)
            ->orderBy('id', $direction)
            ->paginate($request->validated('per_page', 15));
        $response = ApiResponse::paginated('Percobaan speaking siswa berhasil diambil.', $attempts, SpeakingAttemptResource::collection($attempts->getCollection())->resolve());
        $response->setData(array_replace_recursive($response->getData(true), ['meta' => ['counts' => $counts]]));

        return $response;
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
            'status' => 'reviewed',
        ])->save();

        return ApiResponse::success('Feedback speaking berhasil disimpan.', new SpeakingAttemptResource($attempt->refresh()->load(['exercise', 'student', 'reviewer'])));
    }
}
