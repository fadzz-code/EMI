<?php

namespace App\Policies;

use App\Models\MediaFile;
use App\Models\SpeakingAttempt;
use App\Models\User;

class MediaFilePolicy
{
    public function view(User $user, MediaFile $mediaFile): bool
    {
        return $user->role === 'admin'
            || $mediaFile->uploaded_by === $user->id
            || $mediaFile->isPublic()
            || $this->teacherCanReviewSpeakingRecording($user, $mediaFile);
    }

    public function upload(User $user, string $purpose): bool
    {
        if ($user->status !== 'approved') {
            return false;
        }

        return match ($user->role) {
            'admin' => in_array($purpose, ['avatar', 'question_image', 'lesson_image', 'culture_media', 'document', 'audio', 'speaking_recording', 'speaking_reference_audio', 'login_banner'], true),
            'teacher' => in_array($purpose, ['avatar', 'question_image', 'lesson_image', 'culture_media', 'document', 'audio', 'speaking_reference_audio'], true),
            'student' => in_array($purpose, ['avatar', 'speaking_recording'], true),
            default => false,
        };
    }

    public function requestTemporaryUrl(User $user, MediaFile $mediaFile): bool
    {
        return $mediaFile->isPrivate()
            && ($user->role === 'admin' || $mediaFile->uploaded_by === $user->id || $this->teacherCanReviewSpeakingRecording($user, $mediaFile));
    }

    public function delete(User $user, MediaFile $mediaFile): bool
    {
        return $user->role === 'admin' || $mediaFile->uploaded_by === $user->id;
    }

    public function viewPublicContent(?User $user, MediaFile $mediaFile): bool
    {
        return $mediaFile->isPublic();
    }

    private function teacherCanReviewSpeakingRecording(User $user, MediaFile $mediaFile): bool
    {
        if ($user->role !== 'teacher' || $mediaFile->purpose !== 'speaking_recording') {
            return false;
        }

        $attempt = SpeakingAttempt::query()->with('exercise')->where('audio_media_id', $mediaFile->id)->first();
        $classId = $attempt?->exercise?->classroom_id;

        if (! $classId) {
            return false;
        }

        return $user->teacherClassAssignments()->where('class_id', $classId)->where('is_active', true)->exists();
    }
}
