<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Jobs\AnalyzeSpeakingAttemptJob;
use App\Jobs\DeleteStoredFiles;
use App\Models\MediaFile;
use App\Models\SpeakingAttempt;
use App\Models\SpeakingExercise;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;

class SpeakingAttemptService
{
    public function __construct(
        private readonly MediaUploadService $mediaUploadService,
        private readonly SpeakingAuthorizationService $authorizationService,
        private readonly MediaUsageService $mediaUsageService,
    ) {}

    public function create(User $student, SpeakingExercise $exercise, UploadedFile $file, Request $request, ?int $durationSeconds = null, string $captureSource = 'web_microphone'): SpeakingAttempt
    {
        return DB::transaction(function () use ($student, $exercise, $file, $request, $durationSeconds, $captureSource): SpeakingAttempt {
            $lockedExercise = SpeakingExercise::query()->lockForUpdate()->find($exercise->id);
            if (! $lockedExercise || ! $this->studentCanAccessExercise($student, $lockedExercise)) {
                throw new ApiException('Latihan speaking tidak dapat diakses.', 'SPEAKING_EXERCISE_FORBIDDEN', 403);
            }

            $media = $this->mediaUploadService->upload($student, $file, 'speaking_recording', 'private', [
                'speaking_exercise_id' => $lockedExercise->id,
                'audio_duration_seconds' => $durationSeconds,
            ], $request);

            $attempt = SpeakingAttempt::query()->create([
                'speaking_exercise_id' => $lockedExercise->id,
                'student_id' => $student->id,
                'audio_media_id' => $media->id,
                'audio_path' => $media->path,
                'audio_disk' => $media->disk,
                'audio_mime_type' => $media->mime_type,
                'audio_size_bytes' => $media->size_bytes,
                'audio_duration_seconds' => $durationSeconds,
                'capture_source' => $captureSource,
                'target_text_snapshot' => $lockedExercise->target_text,
                'status' => 'pending',
                'analysis_status' => 'pending',
                'review_status' => 'pending',
            ]);

            if (config('queue.default') === 'sync') {
                AnalyzeSpeakingAttemptJob::dispatchSync($attempt->id);
            } else {
                AnalyzeSpeakingAttemptJob::dispatch($attempt->id)->afterCommit();
            }

            return $attempt->refresh()->load(['exercise', 'audioMedia']);
        });
    }

    public function submit(User $student, SpeakingAttempt $attempt): SpeakingAttempt
    {
        try {
            return DB::transaction(function () use ($student, $attempt): SpeakingAttempt {
                SpeakingExercise::query()->whereKey($attempt->speaking_exercise_id)->lockForUpdate()->firstOrFail();
                User::query()->whereKey($student->id)->lockForUpdate()->firstOrFail();
                $attempt = SpeakingAttempt::query()->whereKey($attempt->id)->lockForUpdate()->firstOrFail();
                if ($attempt->student_id !== $student->id) {
                    throw new ApiException('Percobaan speaking tidak dapat diakses.', 'SPEAKING_ATTEMPT_FORBIDDEN', 403);
                }
                if ($attempt->submitted_at) {
                    return $attempt;
                }
                if ($attempt->analysis_status !== 'completed') {
                    throw new ApiException('Hanya percobaan dengan analisis AI selesai yang dapat dikirim.', 'SPEAKING_ATTEMPT_ANALYSIS_INCOMPLETE', 409);
                }

                $canonical = SpeakingAttempt::query()
                    ->where('student_id', $student->id)
                    ->where('speaking_exercise_id', $attempt->speaking_exercise_id)
                    ->whereNotNull('submitted_at')
                    ->lockForUpdate()
                    ->first();
                if ($canonical?->review_status === 'reviewed') {
                    throw new ApiException('Percobaan yang sudah direview tidak dapat diganti.', 'SPEAKING_ATTEMPT_REVIEWED', 409);
                }
                if ($canonical) {
                    $this->deleteLocked($canonical);
                }

                $attempt->forceFill(['submitted_at' => now()])->save();

                return $attempt->refresh()->load(['exercise', 'audioMedia']);
            });
        } catch (QueryException $exception) {
            if (in_array($exception->getCode(), ['23000', '23505'], true)) {
                throw new ApiException('Percobaan aktif untuk latihan ini sudah ada.', 'SPEAKING_ATTEMPT_ALREADY_SUBMITTED', 409, previous: $exception);
            }

            throw $exception;
        }
    }

    public function deleteForStudent(User $student, SpeakingAttempt $attempt): void
    {
        DB::transaction(function () use ($student, $attempt): void {
            $attempt = SpeakingAttempt::query()->whereKey($attempt->id)->lockForUpdate()->firstOrFail();
            if ($attempt->student_id !== $student->id) {
                throw new ApiException('Percobaan speaking tidak dapat diakses.', 'SPEAKING_ATTEMPT_FORBIDDEN', 403);
            }
            if ($attempt->submitted_at) {
                throw new ApiException('Percobaan yang sudah dikirim tidak dapat dihapus oleh siswa.', 'SPEAKING_ATTEMPT_SUBMITTED', 409);
            }
            $this->deleteLocked($attempt);
        });
    }

    public function deletePrivateHistory(User $student, SpeakingExercise $exercise): int
    {
        return DB::transaction(function () use ($student, $exercise): int {
            SpeakingExercise::query()->whereKey($exercise->id)->lockForUpdate()->firstOrFail();
            $attempts = SpeakingAttempt::query()->where('student_id', $student->id)->where('speaking_exercise_id', $exercise->id)->whereNull('submitted_at')->lockForUpdate()->get();
            $attempts->each(fn (SpeakingAttempt $attempt) => $this->deleteLocked($attempt));

            return $attempts->count();
        });
    }

    public function deletePendingForTeacher(User $teacher, SpeakingAttempt $attempt): void
    {
        DB::transaction(function () use ($teacher, $attempt): void {
            $attempt = SpeakingAttempt::query()->whereKey($attempt->id)->lockForUpdate()->firstOrFail();
            if (! $attempt->submitted_at) {
                throw new ApiException('Percobaan privat tidak dapat diakses oleh guru.', 'SPEAKING_ATTEMPT_NOT_SUBMITTED', 409);
            }
            if (! $this->teacherCanAccess($teacher, $attempt->load('exercise'))) {
                throw new ApiException('Percobaan speaking tidak dapat diakses.', 'SPEAKING_ATTEMPT_FORBIDDEN', 403);
            }
            if ($attempt->review_status !== 'pending') {
                throw new ApiException('Hanya kiriman yang belum direview yang dapat dihapus.', 'SPEAKING_ATTEMPT_REVIEWED', 409);
            }
            $this->deleteLocked($attempt);
        });
    }

    public function review(User $teacher, SpeakingAttempt $attempt, ?float $score, ?string $feedback): SpeakingAttempt
    {
        return DB::transaction(function () use ($teacher, $attempt, $score, $feedback): SpeakingAttempt {
            $attempt = SpeakingAttempt::query()->whereKey($attempt->id)->lockForUpdate()->firstOrFail();
            if (! $attempt->submitted_at) {
                throw new ApiException('Percobaan privat tidak dapat direview.', 'SPEAKING_ATTEMPT_NOT_SUBMITTED', 409);
            }
            if (! $this->teacherCanAccess($teacher, $attempt->load('exercise'))) {
                throw new ApiException('Percobaan speaking tidak dapat diakses.', 'SPEAKING_ATTEMPT_FORBIDDEN', 403);
            }

            $attempt->forceFill([
                'teacher_score' => $score,
                'teacher_feedback' => $feedback,
                'reviewed_by_id' => $teacher->id,
                'reviewed_at' => now(),
                'review_status' => 'reviewed',
                'status' => 'reviewed',
            ])->save();

            return $attempt->refresh()->load(['exercise', 'student', 'reviewer']);
        });
    }

    private function deleteLocked(SpeakingAttempt $attempt): void
    {
        $media = $attempt->audio_media_id ? MediaFile::query()->whereKey($attempt->audio_media_id)->lockForUpdate()->first() : null;
        $attempt->delete();
        if ($media && ! $this->mediaUsageService->isInUse($media)) {
            $file = ['disk' => $media->disk, 'path' => $media->path];
            $media->delete();
            DeleteStoredFiles::dispatch([$file])->afterCommit();
        }
    }

    public function teacherCanAccess(User $teacher, SpeakingAttempt $attempt): bool
    {
        return $this->authorizationService->teacherCanAccessAttempt($teacher, $attempt);
    }

    public function studentCanAccessExercise(User $student, SpeakingExercise $exercise): bool
    {
        if ($exercise->status !== 'published') {
            return false;
        }

        return $student->studentClassMemberships()
            ->where('class_id', $exercise->classroom_id)
            ->where('is_active', true)
            ->exists();
    }
}
