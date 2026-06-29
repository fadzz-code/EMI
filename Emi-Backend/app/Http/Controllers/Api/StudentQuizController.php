<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Quiz\ListStudentQuizzesRequest;
use App\Http\Resources\StudentQuizResource;
use App\Models\ClassQuiz;
use App\Models\QuizAttempt;
use App\Services\QuizAccessService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

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

        $quizzes = $this->withStudentAttemptSummary(ClassQuiz::query(), $request->user()->id)
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
        $quiz = $this->withStudentAttemptSummary(ClassQuiz::query(), $request->user()->id)
            ->with('questions.options', 'questions.imageMedia')
            ->withCount(['questions', 'attempts' => fn ($query) => $query->where('student_id', $request->user()->id)])
            ->findOrFail($id);
        if (! $this->accessService->studentCanAccessQuiz($request->user(), $quiz)) {
            abort(404);
        }

        return ApiResponse::success('Detail kuis siswa berhasil diambil.', new StudentQuizResource($quiz));
    }

    private function withStudentAttemptSummary($query, string $studentId)
    {
        $submittedAttempts = QuizAttempt::query()
            ->select('class_quiz_id')
            ->selectRaw('count(*)::int as submitted_attempts_count')
            ->selectRaw('max(score_percent) as best_score_percent')
            ->selectRaw('(array_agg(score_points order by submitted_at desc, id desc))[1] as latest_score_points')
            ->selectRaw('(array_agg(max_points order by submitted_at desc, id desc))[1] as latest_max_points')
            ->selectRaw('(array_agg(score_percent order by submitted_at desc, id desc))[1] as latest_score_percent')
            ->selectRaw('max(submitted_at) as latest_submitted_at')
            ->where('student_id', $studentId)
            ->where('status', 'submitted')
            ->groupBy('class_quiz_id');

        return $query->leftJoinSub($submittedAttempts, 'student_submitted_attempts', fn ($join) => $join->on('student_submitted_attempts.class_quiz_id', '=', 'class_quizzes.id'))
            ->addSelect('class_quizzes.*')
            ->addSelect([
                DB::raw('student_submitted_attempts.submitted_attempts_count as submitted_attempts_count'),
                DB::raw('student_submitted_attempts.best_score_percent as best_score_percent'),
                DB::raw('student_submitted_attempts.latest_score_points as latest_score_points'),
                DB::raw('student_submitted_attempts.latest_max_points as latest_max_points'),
                DB::raw('student_submitted_attempts.latest_score_percent as latest_score_percent'),
                DB::raw('student_submitted_attempts.latest_submitted_at as latest_submitted_at'),
            ]);
    }
}
