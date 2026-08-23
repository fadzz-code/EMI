<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Speaking\ListSpeakingAttemptsRequest;
use App\Http\Requests\Speaking\StoreSpeakingAttemptRequest;
use App\Http\Resources\SpeakingAttemptResource;
use App\Http\Resources\SpeakingExerciseResource;
use App\Models\SpeakingAttempt;
use App\Models\SpeakingExercise;
use App\Services\SpeakingAttemptService;
use Illuminate\Http\JsonResponse;

class StudentSpeakingController extends Controller
{
    public function __construct(private readonly SpeakingAttemptService $attemptService) {}

    public function exercises(): JsonResponse
    {
        $user = request()->user();
        $classIds = $user->studentClassMemberships()->where('is_active', true)->pluck('class_id');
        $exercises = SpeakingExercise::query()
            ->with(['referenceAudio'])
            ->published()
            ->whereIn('classroom_id', $classIds)
            ->orderBy('created_at')
            ->get();

        return ApiResponse::success('Latihan speaking berhasil diambil.', SpeakingExerciseResource::collection($exercises)->resolve());
    }

    public function showExercise(SpeakingExercise $exercise): JsonResponse
    {
        abort_unless($this->attemptService->studentCanAccessExercise(request()->user(), $exercise), 403);

        return ApiResponse::success('Detail latihan speaking berhasil diambil.', new SpeakingExerciseResource($exercise->load(['referenceAudio'])));
    }

    public function attempts(ListSpeakingAttemptsRequest $request): JsonResponse
    {
        $sort = $request->validated('sort', 'created_at');
        $direction = $request->validated('direction', 'desc');
        $attempts = SpeakingAttempt::query()
            ->with(['exercise', 'reviewer'])
            ->forStudent($request->user())
            ->when($request->validated('analysis_status'), fn ($query, $status) => $query->where('analysis_status', $status))
            ->when($request->validated('review_status'), fn ($query, $status) => $query->where('review_status', $status))
            ->orderBy($sort, $direction)
            ->orderBy('id', $direction)
            ->paginate($request->validated('per_page', 15));

        return ApiResponse::paginated('Percobaan speaking berhasil diambil.', $attempts, SpeakingAttemptResource::collection($attempts->getCollection())->resolve());
    }

    public function showAttempt(SpeakingAttempt $attempt): JsonResponse
    {
        abort_unless($attempt->student_id === request()->user()->id, 403);

        return ApiResponse::success('Detail percobaan speaking berhasil diambil.', new SpeakingAttemptResource($attempt->load(['exercise', 'reviewer'])));
    }

    public function submitAttempt(SpeakingAttempt $attempt): JsonResponse
    {
        $attempt = $this->attemptService->submit(request()->user(), $attempt);

        return ApiResponse::success('Percobaan speaking berhasil dikirim.', new SpeakingAttemptResource($attempt));
    }

    public function destroyAttempt(SpeakingAttempt $attempt): JsonResponse
    {
        $this->attemptService->deleteForStudent(request()->user(), $attempt);

        return ApiResponse::success('Percobaan speaking berhasil dihapus.');
    }

    public function destroyPrivateHistory(SpeakingExercise $exercise): JsonResponse
    {
        $count = $this->attemptService->deletePrivateHistory(request()->user(), $exercise);

        return ApiResponse::success('Riwayat speaking privat untuk latihan berhasil dihapus.', [
            'exercise_id' => $exercise->id,
            'deleted_count' => $count,
        ]);
    }

    public function storeAttempt(StoreSpeakingAttemptRequest $request, SpeakingExercise $exercise): JsonResponse
    {
        abort_unless($this->attemptService->studentCanAccessExercise($request->user(), $exercise), 403);

        $attempt = $this->attemptService->create(
            $request->user(),
            $exercise,
            $request->file('file'),
            $request,
            $request->validated('audio_duration_seconds'),
            $request->validated('capture_source', 'web_microphone'),
        );

        return ApiResponse::success('Latihan speaking privat berhasil dibuat.', new SpeakingAttemptResource($attempt), 201);
    }
}
