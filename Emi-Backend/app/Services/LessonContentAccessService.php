<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\ClassLesson;
use App\Models\User;

class LessonContentAccessService
{
    public function __construct(
        private readonly LearningAccessService $accessService,
        private readonly MediaAccessService $mediaAccessService,
    ) {}

    public function content(User $user, ClassLesson $lesson): array
    {
        $lesson->loadMissing('media', 'classModule.schoolClass.school');

        $allowed = match ($user->role) {
            'admin' => true,
            'teacher' => $this->accessService->canManageLesson($user, $lesson),
            'student' => $this->accessService->studentCanAccessLesson($user, $lesson),
            default => false,
        };

        if (! $allowed) {
            throw new ApiException('Materi tidak dapat diakses.', 'LESSON_NOT_ACCESSIBLE', 404);
        }

        if ($lesson->content_type === 'text') {
            return ['type' => 'text', 'content_body' => $lesson->content_body, 'url' => null];
        }

        if (in_array($lesson->content_type, ['video', 'link'], true)) {
            return ['type' => $lesson->content_type, 'content_body' => null, 'url' => $lesson->external_url];
        }

        if (! $lesson->media) {
            throw new ApiException('Media materi tidak tersedia.', 'INVALID_LESSON_MEDIA', 422);
        }

        $url = $lesson->media->isPublic()
            ? $this->mediaAccessService->publicUrl($lesson->media)
            : $this->mediaAccessService->temporaryUrl($lesson->media, now()->addMinutes((int) config('media.signed_url_ttl_minutes')), 'inline');

        return [
            'type' => $lesson->content_type,
            'content_body' => null,
            'url' => $url,
            'media' => [
                'id' => $lesson->media->id,
                'mime_type' => $lesson->media->mime_type,
                'visibility' => $lesson->media->visibility,
            ],
        ];
    }
}
