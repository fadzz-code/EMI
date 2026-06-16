<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Quiz\ReorderQuizQuestionsRequest;
use App\Http\Requests\Quiz\StoreQuizQuestionRequest;
use App\Http\Requests\Quiz\UpdateQuizQuestionRequest;
use App\Http\Resources\QuizTemplateQuestionResource;
use App\Models\QuizTemplate;
use App\Models\QuizTemplateQuestion;
use App\Services\QuizTemplateQuestionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class AdminQuizTemplateQuestionController extends Controller
{
    public function __construct(private readonly QuizTemplateQuestionService $service) {}

    public function index(string $templateId): JsonResponse
    {
        $template = QuizTemplate::query()->with('questions.options', 'questions.imageMedia')->findOrFail($templateId);
        Gate::authorize('view', $template);

        return ApiResponse::success('Data soal template kuis berhasil diambil.', QuizTemplateQuestionResource::collection($template->questions));
    }

    public function store(StoreQuizQuestionRequest $request, string $templateId): JsonResponse
    {
        $template = QuizTemplate::query()->findOrFail($templateId);
        Gate::authorize('create', QuizTemplateQuestion::class);

        return ApiResponse::success('Soal template kuis berhasil dibuat.', new QuizTemplateQuestionResource($this->service->create($template, $request->validated(), $request->user(), $request)), 201);
    }

    public function show(string $id): JsonResponse
    {
        $question = QuizTemplateQuestion::query()->with('quizTemplate', 'options', 'imageMedia')->findOrFail($id);
        Gate::authorize('view', $question);

        return ApiResponse::success('Detail soal template kuis berhasil diambil.', new QuizTemplateQuestionResource($question));
    }

    public function update(UpdateQuizQuestionRequest $request, string $id): JsonResponse
    {
        $question = QuizTemplateQuestion::query()->with('quizTemplate')->findOrFail($id);
        Gate::authorize('update', $question);

        return ApiResponse::success('Soal template kuis berhasil diperbarui.', new QuizTemplateQuestionResource($this->service->update($question, $request->validated(), $request->user(), $request)));
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $question = QuizTemplateQuestion::query()->with('quizTemplate')->findOrFail($id);
        Gate::authorize('delete', $question);
        $this->service->delete($question, $request->user(), $request);

        return ApiResponse::success('Soal template kuis berhasil dihapus.', []);
    }

    public function reorder(ReorderQuizQuestionsRequest $request, string $templateId): JsonResponse
    {
        $template = QuizTemplate::query()->findOrFail($templateId);
        Gate::authorize('update', $template);
        $this->service->reorder($template, $request->validated('question_ids'), $request->user(), $request);

        return ApiResponse::success('Urutan soal template kuis berhasil diperbarui.', []);
    }
}
