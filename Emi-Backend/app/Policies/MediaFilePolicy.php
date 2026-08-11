<?php

namespace App\Policies;

use App\Models\ClassCultureItem;
use App\Models\MediaFile;
use App\Models\SpeakingAttempt;
use App\Models\User;
use App\Services\SpeakingAuthorizationService;

class MediaFilePolicy
{
    public function __construct(private readonly SpeakingAuthorizationService $speakingAuthorizationService) {}

    public function view(User $user, MediaFile $mediaFile): bool
    {
        return $user->role === 'admin'
            || $mediaFile->uploaded_by === $user->id
            || ($mediaFile->isPublic() && $mediaFile->purpose !== 'culture_media')
            || $this->canAccessCultureMedia($user, $mediaFile)
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
            && ($user->role === 'admin' || $mediaFile->uploaded_by === $user->id || $this->canAccessCultureMedia($user, $mediaFile) || $this->teacherCanReviewSpeakingRecording($user, $mediaFile));
    }

    public function delete(User $user, MediaFile $mediaFile): bool
    {
        return $user->role === 'admin' || $mediaFile->uploaded_by === $user->id;
    }

    public function viewPublicContent(?User $user, MediaFile $mediaFile): bool
    {
        return $mediaFile->isPublic();
    }

    private function canAccessCultureMedia(User $user, MediaFile $mediaFile): bool
    {
        if ($mediaFile->purpose !== 'culture_media') {
            return false;
        }

        $items = ClassCultureItem::query()
            ->where('media_id', $mediaFile->id)
            ->where('status', 'published')
            ->whereHas('schoolClass', fn ($query) => $query
                ->where('status', 'active')
                ->whereHas('school', fn ($school) => $school->where('status', 'active')));

        return match ($user->role) {
            'teacher' => $items->whereIn('class_id', $user->teacherClassAssignments()->where('is_active', true)->select('class_id'))->exists(),
            'student' => $items->whereIn('class_id', $user->studentClassMemberships()->where('is_active', true)->select('class_id'))->exists(),
            default => false,
        };
    }

    private function teacherCanReviewSpeakingRecording(User $user, MediaFile $mediaFile): bool
    {
        if ($user->role !== 'teacher' || $mediaFile->purpose !== 'speaking_recording') {
            return false;
        }

        $attempt = SpeakingAttempt::query()->where('audio_media_id', $mediaFile->id)->first();

        return $attempt && $this->speakingAuthorizationService->teacherCanAccessAttempt($user, $attempt);
    }
}
