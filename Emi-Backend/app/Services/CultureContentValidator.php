<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\MediaFile;
use App\Models\User;
use Illuminate\Support\Facades\Gate;

class CultureContentValidator
{
    private const FILE_TYPES = ['image', 'audio', 'pdf', 'video'];

    private const URL_TYPES = ['youtube', 'article', 'link'];

    public function normalize(array $data, ?string $previousType = null): array
    {
        $type = $data['content_type'] ?? $previousType;

        if ($type !== null && $type !== $previousType) {
            if (in_array($type, self::FILE_TYPES, true)) {
                $data['external_url'] = null;
            } elseif (in_array($type, self::URL_TYPES, true)) {
                $data['media_id'] = null;
            }
        }

        return $data;
    }

    public function validate(array $data, User $actor): void
    {
        $type = $data['content_type'] ?? null;

        if (in_array($type, self::FILE_TYPES, true)) {
            if (empty($data['media_id']) || ! empty($data['external_url'])) {
                throw new ApiException('Media wajib diisi dan URL harus kosong untuk tipe konten file.', 'VALIDATION_ERROR', 422);
            }

            $media = MediaFile::query()->active()->find($data['media_id']);
            if (! $media || $media->purpose !== 'culture_media') {
                throw new ApiException('Media budaya harus menggunakan media culture_media yang aktif.', 'VALIDATION_ERROR', 422);
            }
            if (! Gate::forUser($actor)->allows('delete', $media)) {
                throw new ApiException('Media budaya tidak dapat digunakan.', 'MEDIA_FORBIDDEN', 403);
            }

            $matches = match ($type) {
                'image' => str_starts_with($media->mime_type, 'image/'),
                'audio' => str_starts_with($media->mime_type, 'audio/'),
                'video' => in_array($media->mime_type, ['video/mp4', 'video/webm'], true),
                'pdf' => $media->mime_type === 'application/pdf',
                default => false,
            };
            if (! $matches) {
                throw new ApiException('Jenis media tidak sesuai dengan tipe konten.', 'VALIDATION_ERROR', 422);
            }

            return;
        }

        if (in_array($type, self::URL_TYPES, true)) {
            $url = $data['external_url'] ?? null;
            $scheme = is_string($url) ? strtolower((string) parse_url($url, PHP_URL_SCHEME)) : '';
            if (! in_array($scheme, ['http', 'https'], true) || ! empty($data['media_id'])) {
                throw new ApiException('URL HTTP/HTTPS wajib diisi dan media harus kosong untuk tipe konten tautan.', 'VALIDATION_ERROR', 422);
            }
        }
    }
}
