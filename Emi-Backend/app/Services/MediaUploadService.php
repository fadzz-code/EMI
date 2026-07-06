<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\MediaFile;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Throwable;

class MediaUploadService
{
    public function __construct(private readonly AuditLogService $auditLogService) {}

    public function upload(User $user, UploadedFile $file, string $purpose, string $visibility, array $metadata, Request $request): MediaFile
    {
        if (Gate::forUser($user)->denies('upload', [MediaFile::class, $purpose])) {
            throw new ApiException('Anda tidak memiliki izin untuk mengunggah media ini.', 'FORBIDDEN', 403);
        }

        $visibility = $this->normalizeVisibility($purpose, $visibility);
        $mimeType = (string) $file->getMimeType();
        $clientExtension = strtolower($file->getClientOriginalExtension());
        $this->validateMime($purpose, $mimeType, $clientExtension);
        $this->validateSize($purpose, (int) $file->getSize());

        $extension = config("media.extensions.{$mimeType}");

        if ($mimeType === 'application/octet-stream' && $purpose === 'speaking_recording') {
            $extension = $clientExtension;
        }

        if (! is_string($extension) || $extension === '') {
            throw new ApiException('Jenis file tidak didukung.', 'MEDIA_MIME_NOT_ALLOWED', 422);
        }

        $mediaId = (string) Str::uuid();
        $storedName = "{$mediaId}.{$extension}";
        $disk = $visibility === 'public' ? config('media.public_disk') : config('media.private_disk');
        $path = $this->logicalPath($purpose, $user->id, $storedName);
        $checksum = hash_file('sha256', $file->getRealPath());
        $stream = fopen($file->getRealPath(), 'rb');

        if ($stream === false) {
            throw new ApiException('File media tidak dapat dibaca.', 'MEDIA_STORAGE_ERROR', 503);
        }

        try {
            $stored = Storage::disk($disk)->put($path, $stream, [
                'visibility' => $visibility,
            ]);
        } finally {
            if (is_resource($stream)) {
                fclose($stream);
            }
        }

        if (! $stored) {
            throw new ApiException('Media gagal disimpan.', 'MEDIA_STORAGE_ERROR', 503);
        }

        try {
            return DB::transaction(function () use ($user, $file, $purpose, $visibility, $metadata, $request, $mimeType, $extension, $mediaId, $storedName, $disk, $path, $checksum) {
                $mediaFile = MediaFile::query()->create([
                    'id' => $mediaId,
                    'uploaded_by' => $user->id,
                    'purpose' => $purpose,
                    'original_name' => $this->safeOriginalName($file->getClientOriginalName()),
                    'stored_name' => $storedName,
                    'disk' => $disk,
                    'path' => $path,
                    'mime_type' => $mimeType,
                    'extension' => $extension,
                    'size_bytes' => (int) $file->getSize(),
                    'checksum_sha256' => $checksum,
                    'visibility' => $visibility,
                    'metadata' => $metadata,
                ]);

                $this->auditLogService->record('media.uploaded', $mediaFile, $user, null, [
                    'purpose' => $purpose,
                    'visibility' => $visibility,
                    'mime_type' => $mimeType,
                    'size_bytes' => (int) $file->getSize(),
                ], [], $request);

                return $mediaFile;
            });
        } catch (Throwable $e) {
            Storage::disk($disk)->delete($path);

            if ($e instanceof ApiException) {
                throw $e;
            }

            throw new ApiException('Metadata media gagal disimpan.', 'MEDIA_DATABASE_ERROR', 500);
        }
    }

    public function normalizeVisibility(string $purpose, string $visibility): string
    {
        return match ($purpose) {
            'avatar' => 'public',
            'speaking_recording' => 'private',
            default => $visibility,
        };
    }

    private function validateMime(string $purpose, string $mimeType, string $clientExtension): void
    {
        $allowed = config("media.allowed_mimes.{$purpose}", []);

        if (in_array($mimeType, $allowed, true)) {
            return;
        }

        $safeExtensions = ['webm', 'wav', 'mp3', 'm4a', 'mp4', 'mpeg', 'mpga', 'ogg', 'oga'];

        if ($purpose === 'speaking_recording' && $mimeType === 'application/octet-stream' && in_array($clientExtension, $safeExtensions, true)) {
            return;
        }

        throw new ApiException('Jenis file tidak sesuai dengan tujuan unggahan.', 'MEDIA_MIME_NOT_ALLOWED', 422, [
            'file' => ['Jenis file tidak sesuai dengan tujuan unggahan.'],
        ]);
    }

    private function validateSize(string $purpose, int $sizeBytes): void
    {
        $maxKb = match ($purpose) {
            'avatar', 'question_image', 'lesson_image' => (int) config('media.max_kb.image'),
            'document', 'culture_media' => (int) config('media.max_kb.document'),
            'audio', 'speaking_recording', 'speaking_reference_audio' => (int) config('media.max_kb.audio'),
            default => 0,
        };

        if ($maxKb < 1 || $sizeBytes > $maxKb * 1024) {
            throw new ApiException('Ukuran file melebihi batas yang diizinkan.', 'MEDIA_FILE_TOO_LARGE', 422, [
                'file' => ['Ukuran file melebihi batas yang diizinkan.'],
            ]);
        }
    }

    private function logicalPath(string $purpose, string $uploaderId, string $storedName): string
    {
        return sprintf(
            'media/%s/%s/%s/%s/%s',
            $purpose,
            now()->format('Y'),
            now()->format('m'),
            $uploaderId,
            $storedName,
        );
    }

    private function safeOriginalName(string $name): string
    {
        $safe = preg_replace('/[^\w.\- ]+/', '_', $name) ?: 'media';
        $safe = trim(str_replace(["\r", "\n"], '_', $safe));

        return $safe !== '' ? $safe : 'media';
    }
}
