<?php

namespace App\Policies;

use App\Models\MediaFile;
use App\Models\User;

class MediaFilePolicy
{
    public function view(User $user, MediaFile $mediaFile): bool
    {
        return $user->role === 'admin'
            || $mediaFile->uploaded_by === $user->id
            || $mediaFile->isPublic();
    }

    public function upload(User $user, string $purpose): bool
    {
        if ($user->status !== 'approved') {
            return false;
        }

        return match ($user->role) {
            'admin' => in_array($purpose, ['avatar', 'question_image', 'lesson_image', 'document', 'audio', 'speaking_recording'], true),
            'teacher' => in_array($purpose, ['avatar', 'question_image', 'lesson_image', 'document', 'audio'], true),
            'student' => in_array($purpose, ['avatar', 'speaking_recording'], true),
            default => false,
        };
    }

    public function requestTemporaryUrl(User $user, MediaFile $mediaFile): bool
    {
        return $mediaFile->isPrivate()
            && ($user->role === 'admin' || $mediaFile->uploaded_by === $user->id);
    }

    public function delete(User $user, MediaFile $mediaFile): bool
    {
        return $user->role === 'admin' || $mediaFile->uploaded_by === $user->id;
    }

    public function viewPublicContent(?User $user, MediaFile $mediaFile): bool
    {
        return $mediaFile->isPublic();
    }
}
