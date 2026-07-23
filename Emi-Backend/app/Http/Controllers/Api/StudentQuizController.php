<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Quiz\ListStudentQuizzesRequest;
use App\Http\Resources\QuizAttemptResource;
use App\Http\Resources\StudentQuizResource;
use App\Models\ClassQuiz;
use App\Models\QuizAttempt;
use App\Services\QuizAccessService;
use App\Services\QuizAttemptService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class StudentQuizController extends Controller
{
    public function __construct(
        private readonly QuizAccessService $accessService,
        private readonly QuizAttemptService $attemptService,
    ) {}

    public function index(ListStudentQuizzesRequest $request): JsonResponse
    {
        $validated = $request->validated();
        $perPage = (int) ($validated['per_page'] ?? 15);
        $sortBy = $validated['sort_by'] ?? 'open_at';
        $sortDirection = $validated['sort_direction'] ?? 'asc';
        $classId = $this->accessService->studentClassId($request->user());
        $this->attemptService->normalizeExpiredForStudent($request->user());

        $quizzes = $this->withStudentAttemptSummary(ClassQuiz::query(), $request->user()->id)
            ->withCount([
                'questions',
                'attempts' => fn ($query) => $query->where('student_id', $request->user()->id),
                'attempts as active_attempts_count' => fn ($query) => $query
                    ->where('student_id', $request->user()->id)
                    ->where('status', 'in_progress'),
            ])
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
        $quiz = ClassQuiz::query()->findOrFail($id);
        if (! $this->accessService->studentCanAccessQuiz($request->user(), $quiz)) {
            abort(404);
        }
        $this->attemptService->normalizeExpiredForStudent($request->user(), $quiz);

        $quiz = $this->withStudentAttemptSummary(ClassQuiz::query(), $request->user()->id)
            ->with('questions.options', 'questions.imageMedia')
            ->withCount([
                'questions',
                'attempts' => fn ($query) => $query->where('student_id', $request->user()->id),
                'attempts as active_attempts_count' => fn ($query) => $query
                    ->where('student_id', $request->user()->id)
                    ->where('status', 'in_progress'),
            ])
            ->findOrFail($id);

        return ApiResponse::success('Detail kuis siswa berhasil diambil.', new StudentQuizResource($quiz));
    }

    public function attempts(ListStudentQuizzesRequest $request, string $id): JsonResponse
    {
        $quiz = ClassQuiz::query()->findOrFail($id);
        if (! $this->accessService->studentCanAccessQuiz($request->user(), $quiz)) {
            abort(404);
        }
        $this->attemptService->normalizeExpiredForStudent($request->user(), $quiz);

        $attempts = QuizAttempt::query()
            ->where('class_quiz_id', $quiz->id)
            ->where('student_id', $request->user()->id)
            ->with('classQuiz')
            ->orderByDesc('attempt_number')
            ->orderByDesc('id')
            ->paginate((int) ($request->validated('per_page') ?? 15));

        return ApiResponse::paginated('Riwayat attempt kuis berhasil diambil.', $attempts, QuizAttemptResource::collection($attempts->getCollection())->resolve());
    }

    private function withStudentAttemptSummary($query, string $studentId)
    {
        $submittedAttempts = QuizAttempt::query()
            ->select('class_quiz_id')
            ->selectRaw("count(*) filter (where status = 'submitted')::int as submitted_attempts_count")
            ->selectRaw("count(*) filter (where status = 'expired')::int as expired_attempts_count")
            ->selectRaw('count(*)::int as finished_attempts_count')
            ->selectRaw('max(score_percent) as best_score_percent')
            ->selectRaw('(array_agg(score_points order by submitted_at desc, id desc))[1] as latest_score_points')
            ->selectRaw('(array_agg(max_points order by submitted_at desc, id desc))[1] as latest_max_points')
            ->selectRaw('(array_agg(score_percent order by submitted_at desc, id desc))[1] as latest_score_percent')
            ->selectRaw('max(submitted_at) as latest_submitted_at')
            ->where('student_id', $studentId)
            ->whereIn('status', ['submitted', 'expired'])
            ->groupBy('class_quiz_id');

        $activeAttempt = fn (string $column) => QuizAttempt::query()
            ->select($column)
            ->whereColumn('class_quiz_id', 'class_quizzes.id')
            ->where('student_id', $studentId)
            ->where('status', 'in_progress')
            ->orderByDesc('attempt_number')
            ->orderByDesc('id')
            ->limit(1);

        return $query->leftJoinSub($submittedAttempts, 'student_submitted_attempts', fn ($join) => $join->on('student_submitted_attempts.class_quiz_id', '=', 'class_quizzes.id'))
            ->addSelect('class_quizzes.*')
            ->addSelect([
                'active_attempt_id' => $activeAttempt('id'),
                'active_attempt_number' => $activeAttempt('attempt_number'),
                'active_attempt_status' => $activeAttempt('status'),
                'active_attempt_started_at' => $activeAttempt('started_at'),
                'active_attempt_expires_at' => $activeAttempt('expires_at'),
                DB::raw('student_submitted_attempts.submitted_attempts_count as submitted_attempts_count'),
                DB::raw('student_submitted_attempts.expired_attempts_count as expired_attempts_count'),
                DB::raw('student_submitted_attempts.finished_attempts_count as finished_attempts_count'),
                DB::raw('student_submitted_attempts.best_score_percent as best_score_percent'),
                DB::raw('student_submitted_attempts.latest_score_points as latest_score_points'),
                DB::raw('student_submitted_attempts.latest_max_points as latest_max_points'),
                DB::raw('student_submitted_attempts.latest_score_percent as latest_score_percent'),
                DB::raw('student_submitted_attempts.latest_submitted_at as latest_submitted_at'),
            ]);
    }
}
