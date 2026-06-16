<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Quiz\ListStudentQuizzesRequest;
use App\Http\Resources\StudentQuizResource;
use App\Models\ClassQuiz;
use App\Services\QuizAccessService;
use Illuminate\Http\JsonResponse;

class StudentQuizController extends Controller
{
    public function __construct(private readonly QuizAccessService $accessService) {}

    public function index(ListStudentQuizzesRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $perPage = (int) ($validated['per_page'] ?? 15);
        $sortBy = $validated['sort_by'] ?? 'open_at';
        $sortDirection = $validated['sort_direction'] ?? 'asc';
        $classId = $this->accessService->studentClassId($request->user());

        $quizzes = ClassQuiz::query()
            ->withCount(['questions', 'attempts' => fn ($query) => $query->where('student_id', $request->user()->id)])
            ->where('class_id', $classId)
            ->where('status', 'published')
            ->whereHas('schoolClass', fn ($query) => $query->where('status', 'active')->whereHas('school', fn ($school) => $school->where('status', 'active')))
            ->when($validated['search'] ?? null, fn ($query, $search) => $query->where(fn ($inner) => $inner->where('title', 'ilike', "%{$search}%")->orWhere('description', 'ilike', "%{$search}%")))
            ->when($validated['availability'] ?? null, function ($query, $availability) {
                if ($availability === 'open') {
                    $query->where(fn ($inner) => $inner->whereNull('open_at')->orWhere('open_at', '<=', now()))
                        ->where(fn ($inner) => $inner->whereNull('close_at')->orWhere('close_at', '>=', now()));
                } elseif ($availability === 'not_open') {
                    $query->where('open_at', '>', now());
                } else {
                    $query->where('close_at', '<', now());
                }
            })
            ->orderBy($sortBy, $sortDirection)
            ->paginate($perPage);

        return ApiResponse::paginated('Data kuis siswa berhasil diambil.', $quizzes, StudentQuizResource::collection($quizzes->getCollection())->resolve());
    }

    public function show(ListStudentQuizzesRequest $request, string $id): JsonResponse
    {
        $quiz = ClassQuiz::query()->with('questions.options', 'questions.imageMedia')->withCount('questions')->findOrFail($id);
        if (! $this->accessService->studentCanAccessQuiz($request->user(), $quiz)) {
            abort(404);
        }

        return ApiResponse::success('Detail kuis siswa berhasil diambil.', new StudentQuizResource($quiz));
    }
}
