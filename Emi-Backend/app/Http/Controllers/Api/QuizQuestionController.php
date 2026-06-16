<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Quiz\ReorderQuizQuestionsRequest;
use App\Http\Requests\Quiz\StoreQuizQuestionRequest;
use App\Http\Requests\Quiz\UpdateQuizQuestionRequest;
use App\Http\Resources\QuizQuestionResource;
use App\Models\ClassQuiz;
use App\Models\QuizQuestion;
use App\Services\QuizQuestionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class QuizQuestionController extends Controller
{
    public function __construct(private readonly QuizQuestionService $service) {}

    public function index(string $quizId): JsonResponse
    {
        $quiz = ClassQuiz::query()->with('questions.options', 'questions.imageMedia')->findOrFail($quizId);
        Gate::authorize('update', $quiz);
        $quiz->questions->each->setAttribute('show_sensitive_answers', true);

        return ApiResponse::success('Data soal kuis berhasil diambil.', QuizQuestionResource::collection($quiz->questions));
    }

    public function store(StoreQuizQuestionRequest $request, string $quizId): JsonResponse
    {
        $quiz = ClassQuiz::query()->findOrFail($quizId);
        Gate::authorize('update', $quiz);
        $question = $this->service->create($quiz, $request->validated(), $request->user(), $request);
        $question->setAttribute('show_sensitive_answers', true);

        return ApiResponse::success('Soal kuis berhasil dibuat.', new QuizQuestionResource($question), 201);
    }

    public function show(string $id): JsonResponse
    {
        $question = QuizQuestion::query()->with('classQuiz', 'options', 'imageMedia')->findOrFail($id);
        Gate::authorize('view', $question);
        $question->setAttribute('show_sensitive_answers', request()->user()?->role !== 'student');

        return ApiResponse::success('Detail soal kuis berhasil diambil.', new QuizQuestionResource($question));
    }

    public function update(UpdateQuizQuestionRequest $request, string $id): JsonResponse
    {
        $question = QuizQuestion::query()->with('classQuiz')->findOrFail($id);
        Gate::authorize('update', $question);
        $question = $this->service->update($question, $request->validated(), $request->user(), $request);
        $question->setAttribute('show_sensitive_answers', true);

        return ApiResponse::success('Soal kuis berhasil diperbarui.', new QuizQuestionResource($question));
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $question = QuizQuestion::query()->with('classQuiz')->findOrFail($id);
        Gate::authorize('delete', $question);
        $this->service->delete($question, $request->user(), $request);

        return ApiResponse::success('Soal kuis berhasil dihapus.', []);
    }

    public function reorder(ReorderQuizQuestionsRequest $request, string $quizId): JsonResponse
    {
        $quiz = ClassQuiz::query()->findOrFail($quizId);
        Gate::authorize('update', $quiz);
        $this->service->reorder($quiz, $request->validated('question_ids'), $request->user(), $request);

        return ApiResponse::success('Urutan soal kuis berhasil diperbarui.', []);
    }
}
