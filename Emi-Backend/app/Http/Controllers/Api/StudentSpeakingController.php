<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
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
            ->where(fn ($query) => $query->whereNull('classroom_id')->orWhereIn('classroom_id', $classIds))
            ->orderBy('created_at')
            ->get();

        return ApiResponse::success('Latihan speaking berhasil diambil.', SpeakingExerciseResource::collection($exercises)->resolve());
    }

    public function showExercise(SpeakingExercise $exercise): JsonResponse
    {
        abort_unless($this->attemptService->studentCanAccessExercise(request()->user(), $exercise), 403);

        return ApiResponse::success('Detail latihan speaking berhasil diambil.', new SpeakingExerciseResource($exercise->load(['referenceAudio'])));
    }

    public function attempts(): JsonResponse
    {
        $attempts = SpeakingAttempt::query()
            ->with('exercise')
            ->forStudent(request()->user())
            ->latest()
            ->get();

        return ApiResponse::success('Percobaan speaking berhasil diambil.', SpeakingAttemptResource::collection($attempts)->resolve());
    }

    public function showAttempt(SpeakingAttempt $attempt): JsonResponse
    {
        abort_unless($attempt->student_id === request()->user()->id, 403);

        return ApiResponse::success('Detail percobaan speaking berhasil diambil.', new SpeakingAttemptResource($attempt->load('exercise')));
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

        return ApiResponse::success('Percobaan speaking berhasil dikirim.', new SpeakingAttemptResource($attempt), 201);
    }
}
