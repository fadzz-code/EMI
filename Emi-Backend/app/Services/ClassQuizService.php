<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\ClassQuiz;
use App\Models\SchoolClass;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ClassQuizService
{
    public function __construct(private readonly AuditLogService $auditLogService, private readonly QuizQuestionValidationService $questionValidationService) {}

    public function create(SchoolClass $class, array $data, User $actor, Request $request): ClassQuiz
    {
        $this->assertActiveClass($class);
        $this->validateSettings($data);

        return DB::transaction(function () use ($class, $data, $actor, $request) {
            $quiz = ClassQuiz::query()->create([
                'class_id' => $class->id,
                'title' => $data['title'],
                'description' => $data['description'] ?? null,
                'instructions' => $data['instructions'] ?? null,
                'duration_minutes' => $data['duration_minutes'],
                'max_attempts' => $data['max_attempts'],
                'show_result' => $data['show_result'] ?? true,
                'open_at' => $data['open_at'] ?? null,
                'close_at' => $data['close_at'] ?? null,
                'status' => $data['status'] ?? 'draft',
                'created_by' => $actor->id,
                'published_at' => ($data['status'] ?? 'draft') === 'published' ? now() : null,
            ]);
            $this->auditLogService->record('class_quiz.created', $quiz, $actor, null, $quiz->only(['class_id', 'title', 'status']), [], $request);

            return $quiz->refresh();
        });
    }

    public function update(ClassQuiz $quiz, array $data, User $actor, Request $request): ClassQuiz
    {
        if ($quiz->status === 'published') {
            $data = collect($data)->only(['show_result'])->all();
            if ($data === []) {
                throw new ApiException('Konten kuis published terkunci.', 'QUIZ_CONTENT_LOCKED', 409);
            }
        }
        if ($quiz->attempts()->exists() && array_intersect(array_keys($data), ['duration_minutes', 'max_attempts', 'open_at', 'close_at'])) {
            throw new ApiException('Kuis sudah memiliki attempt.', 'QUIZ_CONTENT_LOCKED', 409);
        }
        if (($data['status'] ?? null) === 'published') {
            return $this->publish($quiz, $actor, $request);
        }
        $this->validateSettings(array_merge($quiz->only(['duration_minutes', 'max_attempts', 'open_at', 'close_at']), $data));

        return DB::transaction(function () use ($quiz, $data, $actor, $request) {
            $old = $quiz->only(['title', 'status']);
            $quiz->fill(collect($data)->only(['title', 'description', 'instructions', 'duration_minutes', 'max_attempts', 'show_result', 'open_at', 'close_at', 'status'])->all());
            $quiz->updated_by = $actor->id;
            if ($quiz->status === 'archived') {
                $quiz->archived_at = now();
            }
            $quiz->save();
            $this->auditLogService->record('class_quiz.updated', $quiz, $actor, $old, $quiz->only(['title', 'status']), [], $request);

            return $quiz->refresh();
        });
    }

    public function publish(ClassQuiz $quiz, User $actor, Request $request): ClassQuiz
    {
        $quiz->load('schoolClass.school', 'questions.options', 'questions.imageMedia');
        $this->assertActiveClass($quiz->schoolClass);
        if ($quiz->status === 'archived') {
            throw new ApiException('Kuis archived tidak dapat dipublish.', 'QUIZ_ARCHIVED', 409);
        }
        if ($quiz->questions->isEmpty()) {
            throw new ApiException('Kuis harus memiliki soal.', 'QUIZ_HAS_NO_QUESTIONS', 409);
        }
        foreach ($quiz->questions as $question) {
            $this->questionValidationService->validate($question->toArray() + ['options' => $question->options->map(fn ($option) => $option->only(['option_text', 'is_correct', 'order_number']))->all()]);
        }
        $quiz->forceFill(['status' => 'published', 'published_at' => $quiz->published_at ?? now(), 'archived_at' => null, 'updated_by' => $actor->id])->save();
        $this->auditLogService->record('class_quiz.published', $quiz, $actor, null, ['status' => 'published'], [], $request);

        return $quiz->refresh();
    }

    public function archive(ClassQuiz $quiz, User $actor, Request $request): ClassQuiz
    {
        $quiz->forceFill(['status' => 'archived', 'archived_at' => now(), 'updated_by' => $actor->id])->save();
        $this->auditLogService->record('class_quiz.archived', $quiz, $actor, null, ['status' => 'archived'], [], $request);

        return $quiz->refresh();
    }

    public function delete(ClassQuiz $quiz, User $actor, Request $request): void
    {
        if ($quiz->status !== 'draft' || $quiz->attempts()->exists()) {
            throw new ApiException('Kuis memiliki attempt dan harus diarsipkan.', 'QUIZ_HAS_ATTEMPTS', 409);
        }
        $quiz->delete();
        $this->auditLogService->record('class_quiz.deleted', $quiz, $actor, null, ['deleted_at' => now()->toISOString()], [], $request);
    }

    private function assertActiveClass(SchoolClass $class): void
    {
        $class->loadMissing('school');
        if ($class->status !== 'active') {
            throw new ApiException('Kelas tidak aktif.', 'CLASS_INACTIVE', 409);
        }
        if ($class->school?->status !== 'active') {
            throw new ApiException('Sekolah tidak aktif.', 'SCHOOL_INACTIVE', 409);
        }
    }

    private function validateSettings(array $data): void
    {
        if (($data['duration_minutes'] ?? 0) < 1 || ($data['duration_minutes'] ?? 0) > (int) config('quiz.max_duration_minutes')) {
            throw new ApiException('Durasi kuis tidak valid.', 'VALIDATION_ERROR', 422);
        }
        if (($data['max_attempts'] ?? 0) < 1 || ($data['max_attempts'] ?? 0) > (int) config('quiz.max_attempts')) {
            throw new ApiException('Batas percobaan kuis tidak valid.', 'VALIDATION_ERROR', 422);
        }
        if (($data['open_at'] ?? null) && ($data['close_at'] ?? null) && strtotime((string) $data['open_at']) >= strtotime((string) $data['close_at'])) {
            throw new ApiException('Jadwal kuis tidak valid.', 'INVALID_QUIZ_SCHEDULE', 422);
        }
    }
}
