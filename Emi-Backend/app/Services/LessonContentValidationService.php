<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\MediaFile;

class LessonContentValidationService
{
    public function validate(array $data): array
    {
        $type = (string) ($data['content_type'] ?? '');
        $contentBody = $data['content_body'] ?? null;
        $mediaId = $data['media_id'] ?? null;
        $externalUrl = $data['external_url'] ?? null;

        if ($contentBody !== null && $this->containsUnsafeHtml((string) $contentBody)) {
            throw new ApiException('Konten materi tidak aman.', 'INVALID_LESSON_CONTENT', 422);
        }

        return match ($type) {
            'text' => $this->validateText($contentBody, $mediaId, $externalUrl),
            'image' => $this->validateMedia($mediaId, 'lesson_image', $externalUrl),
            'audio' => $this->validateMedia($mediaId, 'audio', $externalUrl),
            'pdf' => $this->validateMedia($mediaId, 'document', $externalUrl),
            'video', 'link' => $this->validateExternalUrl($externalUrl, $mediaId),
            default => throw new ApiException('Tipe konten materi tidak valid.', 'INVALID_LESSON_CONTENT', 422),
        };
    }

    public function assertValidModel(object $lesson): void
    {
        $this->validate([
            'content_type' => $lesson->content_type,
            'content_body' => $lesson->content_body,
            'media_id' => $lesson->media_id,
            'external_url' => $lesson->external_url,
        ]);
    }

    private function validateText(mixed $contentBody, mixed $mediaId, mixed $externalUrl): array
    {
        if (! is_string($contentBody) || trim($contentBody) === '' || $mediaId !== null || $externalUrl !== null) {
            throw new ApiException('Konten text wajib memiliki isi tanpa media atau URL.', 'INVALID_LESSON_CONTENT', 422);
        }

        return ['media_id' => null, 'external_url' => null];
    }

    private function validateMedia(mixed $mediaId, string $purpose, mixed $externalUrl): array
    {
        if (! is_string($mediaId) || $mediaId === '' || $externalUrl !== null) {
            throw new ApiException('Media materi tidak valid.', 'INVALID_LESSON_MEDIA', 422);
        }

        $media = MediaFile::query()->active()->find($mediaId);

        if (! $media || $media->purpose !== $purpose) {
            throw new ApiException('Media materi tidak valid.', 'INVALID_LESSON_MEDIA', 422);
        }

        return ['external_url' => null];
    }

    private function validateExternalUrl(mixed $externalUrl, mixed $mediaId): array
    {
        if (! is_string($externalUrl) || $mediaId !== null || ! filter_var($externalUrl, FILTER_VALIDATE_URL)) {
            throw new ApiException('URL materi tidak valid.', 'INVALID_LESSON_CONTENT', 422);
        }

        if (parse_url($externalUrl, PHP_URL_SCHEME) !== 'https') {
            throw new ApiException('URL materi wajib memakai HTTPS.', 'INVALID_LESSON_CONTENT', 422);
        }

        return ['media_id' => null];
    }

    private function containsUnsafeHtml(string $content): bool
    {
        return preg_match('/<\s*script|<\s*iframe|\son\w+\s*=|javascript\s*:|data\s*:/i', $content) === 1;
    }
}
