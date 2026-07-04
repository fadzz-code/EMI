<?php

namespace App\Services;

use App\Jobs\AnalyzeSpeakingAttemptJob;
use App\Models\MediaFile;
use App\Models\SpeakingAttempt;
use App\Models\SpeakingExercise;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;

class SpeakingAttemptService
{
    public function __construct(private readonly MediaUploadService $mediaUploadService) {}

    public function create(User $student, SpeakingExercise $exercise, UploadedFile $file, Request $request, ?int $durationSeconds = null): SpeakingAttempt
    {
        return DB::transaction(function () use ($student, $exercise, $file, $request, $durationSeconds): SpeakingAttempt {
            $media = $this->mediaUploadService->upload($student, $file, 'speaking_recording', 'private', [
                'speaking_exercise_id' => $exercise->id,
                'audio_duration_seconds' => $durationSeconds,
            ], $request);

            $attempt = SpeakingAttempt::query()->create([
                'speaking_exercise_id' => $exercise->id,
                'student_id' => $student->id,
                'audio_media_id' => $media->id,
                'audio_path' => $media->path,
                'audio_disk' => $media->disk,
                'audio_mime_type' => $media->mime_type,
                'audio_size_bytes' => $media->size_bytes,
                'audio_duration_seconds' => $durationSeconds,
                'target_text_snapshot' => $exercise->target_text,
                'status' => 'pending',
            ]);

            AnalyzeSpeakingAttemptJob::dispatch($attempt->id);

            return $attempt->refresh()->load(['exercise', 'audioMedia']);
        });
    }

    public function teacherCanAccess(User $teacher, SpeakingAttempt $attempt): bool
    {
        $classId = $attempt->exercise?->classroom_id;
        if (! $classId) {
            return false;
        }

        return $teacher->teacherClassAssignments()
            ->where('class_id', $classId)
            ->where('is_active', true)
            ->exists();
    }

    public function studentCanAccessExercise(User $student, SpeakingExercise $exercise): bool
    {
        if ($exercise->status !== 'published') {
            return false;
        }

        if (! $exercise->classroom_id) {
            return true;
        }

        return $student->studentClassMemberships()
            ->where('class_id', $exercise->classroom_id)
            ->where('is_active', true)
            ->exists();
    }
}
