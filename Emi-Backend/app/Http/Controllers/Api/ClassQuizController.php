<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Quiz\ListClassQuizzesRequest;
use App\Http\Requests\Quiz\StoreClassQuizRequest;
use App\Http\Requests\Quiz\UpdateClassQuizRequest;
use App\Http\Resources\ClassQuizResource;
use App\Models\ClassQuiz;
use App\Models\SchoolClass;
use App\Services\ClassQuizService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class ClassQuizController extends Controller
{
    public function __construct(private readonly ClassQuizService $service) {}

    public function index(ListClassQuizzesRequest $request): JsonResponse
    {
        Gate::authorize('viewAny', ClassQuiz::class);
        $validated = $request->validated();
        $perPage = (int) ($validated['per_page'] ?? 15);
        $sortBy = $validated['sort_by'] ?? 'created_at';
        $sortDirection = $validated['sort_direction'] ?? 'desc';

        $quizzes = ClassQuiz::query()
            ->withCount(['questions', 'attempts'])
            ->when($request->user()->role === 'teacher', fn ($query) => $query->where('class_id', $request->user()->activeClassId()))
            ->when($validated['class_id'] ?? null, fn ($query, $classId) => $query->where('class_id', $classId))
            ->when($validated['search'] ?? null, fn ($query, $search) => $query->where(fn ($inner) => $inner->where('title', 'ilike', "%{$search}%")->orWhere('description', 'ilike', "%{$search}%")))
            ->when($validated['status'] ?? null, fn ($query, $status) => $query->where('status', $status))
            ->orderBy($sortBy, $sortDirection)
            ->paginate($perPage);

        return ApiResponse::paginated('Data kuis kelas berhasil diambil.', $quizzes, ClassQuizResource::collection($quizzes->getCollection())->resolve());
    }

    public function store(StoreClassQuizRequest $request): JsonResponse
    {
        $class = SchoolClass::query()->findOrFail($request->validated('class_id'));
        Gate::authorize('createForClass', [ClassQuiz::class, $class]);

        return ApiResponse::success('Kuis kelas berhasil dibuat.', new ClassQuizResource($this->service->create($class, $request->validated(), $request->user(), $request)), 201);
    }

    public function show(string $id): JsonResponse
    {
        $quiz = ClassQuiz::query()->with('questions.options', 'questions.imageMedia')->withCount(['questions', 'attempts'])->findOrFail($id);
        Gate::authorize('view', $quiz);
        $quiz->questions->each->setAttribute('show_sensitive_answers', request()->user()?->role !== 'student');

        return ApiResponse::success('Detail kuis kelas berhasil diambil.', new ClassQuizResource($quiz));
    }

    public function update(UpdateClassQuizRequest $request, string $id): JsonResponse
    {
        $quiz = ClassQuiz::query()->findOrFail($id);
        Gate::authorize('update', $quiz);

        return ApiResponse::success('Kuis kelas berhasil diperbarui.', new ClassQuizResource($this->service->update($quiz, $request->validated(), $request->user(), $request)));
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $quiz = ClassQuiz::query()->findOrFail($id);
        Gate::authorize('delete', $quiz);
        $this->service->delete($quiz, $request->user(), $request);

        return ApiResponse::success('Kuis kelas berhasil dihapus.', []);
    }

    public function publish(Request $request, string $id): JsonResponse
    {
        $quiz = ClassQuiz::query()->findOrFail($id);
        Gate::authorize('update', $quiz);

        return ApiResponse::success('Kuis kelas berhasil dipublish.', new ClassQuizResource($this->service->publish($quiz, $request->user(), $request)));
    }

    public function archive(Request $request, string $id): JsonResponse
    {
        $quiz = ClassQuiz::query()->findOrFail($id);
        Gate::authorize('update', $quiz);

        return ApiResponse::success('Kuis kelas berhasil diarsipkan.', new ClassQuizResource($this->service->archive($quiz, $request->user(), $request)));
    }
}
