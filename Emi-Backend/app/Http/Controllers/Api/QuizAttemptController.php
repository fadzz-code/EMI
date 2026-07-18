<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Quiz\ListQuizAttemptsRequest;
use App\Http\Requests\Quiz\SaveQuizAnswerRequest;
use App\Http\Requests\Quiz\SubmitQuizAttemptRequest;
use App\Http\Resources\QuizAnswerResource;
use App\Http\Resources\QuizAttemptResource;
use App\Models\ClassQuiz;
use App\Models\QuizAttempt;
use App\Models\QuizQuestion;
use App\Services\QuizAttemptService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class QuizAttemptController extends Controller
{
    public function __construct(private readonly QuizAttemptService $service) {}

    public function start(Request $request, string $quizId): JsonResponse
    {
        $quiz = ClassQuiz::query()->findOrFail($quizId);
        $attempt = $this->service->start($quiz, $request->user(), $request);

        return ApiResponse::success('Attempt kuis berhasil dimulai.', new QuizAttemptResource($attempt), 201);
    }

    public function show(Request $request, string $id): JsonResponse
    {
        $attempt = QuizAttempt::query()->with('classQuiz', 'student', 'answers.question', 'answers.selectedOption')->findOrFail($id);
        Gate::authorize('view', $attempt);

        return ApiResponse::success('Detail attempt kuis berhasil diambil.', new QuizAttemptResource($attempt));
    }

    public function saveAnswer(SaveQuizAnswerRequest $request, string $id, string $questionId): JsonResponse
    {
        $attempt = QuizAttempt::query()->findOrFail($id);
        Gate::authorize('update', $attempt);
        $question = QuizQuestion::query()->with('options')->findOrFail($questionId);

        return ApiResponse::success('Jawaban kuis berhasil disimpan.', new QuizAnswerResource($this->service->saveAnswer($attempt, $question, $request->validated(), $request->user(), $request)));
    }

    public function submit(SubmitQuizAttemptRequest $request, string $id): JsonResponse
    {
        $attempt = QuizAttempt::query()->findOrFail($id);
        Gate::authorize('update', $attempt);

        return ApiResponse::success('Attempt kuis berhasil dikumpulkan.', new QuizAttemptResource($this->service->submit($attempt, $request->validated('idempotency_key'), $request->user(), $request)));
    }

    public function indexForQuiz(ListQuizAttemptsRequest $request, string $quizId): JsonResponse
    {
        $quiz = ClassQuiz::query()->findOrFail($quizId);
        Gate::authorize('report', $quiz);
        $validated = $request->validated();
        $perPage = (int) ($validated['per_page'] ?? 15);
        $sortBy = $validated['sort_by'] ?? 'started_at';
        $sortDirection = $validated['sort_direction'] ?? 'desc';

        $attempts = QuizAttempt::query()
            ->where('class_quiz_id', $quiz->id)
            ->with('student', 'answers.selectedOption')
            ->when($validated['student_id'] ?? null, fn ($query, $studentId) => $query->where('student_id', $studentId))
            ->when($validated['status'] ?? null, fn ($query, $status) => $query->where('status', $status))
            ->orderBy($sortBy, $sortDirection)
            ->paginate($perPage);

        return ApiResponse::paginated('Data attempt kuis berhasil diambil.', $attempts, QuizAttemptResource::collection($attempts->getCollection())->resolve());
    }
}
