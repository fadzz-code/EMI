<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\ClassQuiz;
use App\Models\QuizAnswer;
use App\Models\QuizAttempt;
use App\Models\QuizQuestion;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class QuizAttemptService
{
    public function __construct(
        private readonly AuditLogService $auditLogService,
        private readonly QuizAccessService $accessService,
        private readonly QuizGradingService $gradingService,
    ) {}

    public function start(ClassQuiz $quiz, User $student, Request $request): QuizAttempt
    {
        $this->assertStartable($quiz, $student);

        return DB::transaction(function () use ($quiz, $student, $request) {
            $active = QuizAttempt::query()
                ->where('class_quiz_id', $quiz->id)
                ->where('student_id', $student->id)
                ->where('status', 'in_progress')
                ->first();

            if ($active) {
                if (now()->gt($active->expires_at)) {
                    $this->gradingService->finalize($active, 'expired');
                } else {
                    return $active->load('classQuiz.questions.options', 'answers');
                }
            }

            $attempts = QuizAttempt::query()
                ->where('class_quiz_id', $quiz->id)
                ->where('student_id', $student->id)
                ->lockForUpdate()
                ->get();

            if ($attempts->count() >= $quiz->max_attempts) {
                throw new ApiException('Batas attempt kuis tercapai.', 'QUIZ_MAX_ATTEMPTS_REACHED', 409);
            }

            $startedAt = now();
            $expiresAt = $startedAt->copy()->addMinutes($quiz->duration_minutes);
            if ($quiz->close_at && $quiz->close_at->lt($expiresAt)) {
                $expiresAt = $quiz->close_at->copy();
            }

            $attempt = QuizAttempt::query()->create([
                'class_quiz_id' => $quiz->id,
                'student_id' => $student->id,
                'attempt_number' => (int) $attempts->max('attempt_number') + 1,
                'status' => 'in_progress',
                'started_at' => $startedAt,
                'expires_at' => $expiresAt,
                'max_points' => $quiz->questions()->sum('points'),
            ]);
            $this->auditLogService->record('quiz_attempt.started', $attempt, $student, null, ['class_quiz_id' => $quiz->id], [], $request);

            return $attempt->load('classQuiz.questions.options', 'answers');
        });
    }

    public function saveAnswer(QuizAttempt $attempt, QuizQuestion $question, array $data, User $student, Request $request): QuizAnswer
    {
        $attempt = $attempt->load('classQuiz');
        $this->assertAttemptEditable($attempt, $student);

        if ($question->class_quiz_id !== $attempt->class_quiz_id) {
            throw new ApiException('Soal tidak sesuai dengan attempt.', 'QUESTION_NOT_IN_QUIZ', 422);
        }

        if ($question->question_type === 'multiple_choice') {
            $optionId = $data['selected_option_id'] ?? null;
            if (! $optionId || ! $question->options()->whereKey($optionId)->exists()) {
                throw new ApiException('Opsi jawaban tidak valid.', 'INVALID_ANSWER_OPTION', 422);
            }
            $payload = ['selected_option_id' => $optionId, 'answer_text' => null, 'normalized_answer' => null];
        } else {
            if (trim((string) ($data['answer_text'] ?? '')) === '') {
                throw new ApiException('Jawaban isian wajib diisi.', 'VALIDATION_ERROR', 422);
            }
            $payload = ['selected_option_id' => null, 'answer_text' => $data['answer_text']];
        }

        return DB::transaction(function () use ($attempt, $question, $payload, $request, $student) {
            $answer = QuizAnswer::query()->updateOrCreate(
                ['quiz_attempt_id' => $attempt->id, 'quiz_question_id' => $question->id],
                $payload + [
                    'is_correct' => null,
                    'similarity_score' => null,
                    'awarded_points' => 0,
                    'max_points' => $question->points,
                    'answered_at' => now(),
                ],
            );
            $this->auditLogService->record('quiz_answer.saved', $answer, $student, null, ['quiz_attempt_id' => $attempt->id, 'quiz_question_id' => $question->id], [], $request);

            return $answer->refresh()->load('question', 'selectedOption');
        });
    }

    public function submit(QuizAttempt $attempt, string $idempotencyKey, User $student, Request $request): QuizAttempt
    {
        $hash = hash('sha256', $idempotencyKey);

        return DB::transaction(function () use ($attempt, $hash, $student, $request) {
            $attempt = QuizAttempt::query()->lockForUpdate()->with('classQuiz')->findOrFail($attempt->id);
            if ($attempt->student_id !== $student->id) {
                throw new ApiException('Anda tidak memiliki akses ke attempt ini.', 'FORBIDDEN', 403);
            }

            if ($attempt->status !== 'in_progress') {
                if ($attempt->submit_idempotency_key_hash === $hash) {
                    return $attempt->load('answers.question', 'answers.selectedOption');
                }
                throw new ApiException('Attempt sudah selesai.', 'ATTEMPT_ALREADY_SUBMITTED', 409);
            }

            $status = now()->gt($attempt->expires_at) ? 'expired' : 'submitted';
            $attempt->submit_idempotency_key_hash = $hash;
            $attempt->save();
            $attempt = $this->gradingService->finalize($attempt, $status);
            $this->auditLogService->record($status === 'expired' ? 'quiz_attempt.expired' : 'quiz_attempt.submitted', $attempt, $student, null, ['score_percent' => $attempt->score_percent], [], $request);

            return $attempt;
        });
    }

    private function assertStartable(ClassQuiz $quiz, User $student): void
    {
        $quiz->loadMissing('schoolClass.school');
        if (! $this->accessService->studentCanAccessQuiz($student, $quiz)) {
            throw new ApiException('Kuis tidak tersedia.', 'QUIZ_NOT_AVAILABLE', 404);
        }
        if ($quiz->status === 'archived') {
            throw new ApiException('Kuis diarsipkan.', 'QUIZ_ARCHIVED', 409);
        }
        if ($quiz->open_at && now()->lt($quiz->open_at)) {
            throw new ApiException('Kuis belum dibuka.', 'QUIZ_NOT_OPEN', 409);
        }
        if ($quiz->close_at && now()->gt($quiz->close_at)) {
            throw new ApiException('Kuis sudah ditutup.', 'QUIZ_CLOSED', 409);
        }
    }

    private function assertAttemptEditable(QuizAttempt $attempt, User $student): void
    {
        if ($attempt->student_id !== $student->id) {
            throw new ApiException('Anda tidak memiliki akses ke attempt ini.', 'FORBIDDEN', 403);
        }
        if ($attempt->status !== 'in_progress') {
            throw new ApiException('Attempt sudah selesai.', 'ATTEMPT_ALREADY_SUBMITTED', 409);
        }
        if (now()->gt($attempt->expires_at)) {
            $this->gradingService->finalize($attempt, 'expired');
            throw new ApiException('Attempt sudah kedaluwarsa.', 'ATTEMPT_EXPIRED', 409);
        }
    }
}
