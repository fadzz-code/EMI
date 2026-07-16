<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\MediaFile;
use Carbon\CarbonInterface;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\URL;
use Symfony\Component\HttpFoundation\HeaderUtils;
use Symfony\Component\HttpFoundation\StreamedResponse;

class MediaAccessService
{
    public function publicUrl(MediaFile $mediaFile): ?string
    {
        if (! $mediaFile->isPublic()) {
            return null;
        }

        return url("/api/v1/public/media/{$mediaFile->id}/content");
    }

    public function temporaryUrl(MediaFile $mediaFile, CarbonInterface $expiresAt, string $disposition): string
    {
        if (! $mediaFile->isPrivate()) {
            throw new ApiException('Media publik tidak memerlukan tautan sementara.', 'PUBLIC_MEDIA_DOES_NOT_REQUIRE_TEMPORARY_URL', 409);
        }

        $disk = Storage::disk($mediaFile->disk);
        $filename = $this->safeFilename($mediaFile);
        $driver = config("filesystems.disks.{$mediaFile->disk}.driver");

        if ($driver !== 'local' && method_exists($disk, 'providesTemporaryUrls') && $disk->providesTemporaryUrls()) {
            return $disk->temporaryUrl($mediaFile->path, $expiresAt, [
                'ResponseContentDisposition' => HeaderUtils::makeDisposition($disposition, $filename),
                'ResponseContentType' => $mediaFile->mime_type,
            ]);
        }

        $relativeUrl = URL::temporarySignedRoute('media.download', $expiresAt, [
            'id' => $mediaFile->id,
            'disposition' => $disposition,
        ], false);

        return url($relativeUrl);
    }

    public function streamPublic(MediaFile $mediaFile): StreamedResponse
    {
        if (! $mediaFile->isPublic()) {
            throw new ApiException('Media tidak ditemukan.', 'NOT_FOUND', 404);
        }

        return $this->stream($mediaFile, 'inline');
    }

    public function streamPrivate(MediaFile $mediaFile, string $disposition): StreamedResponse
    {
        if (! $mediaFile->isPrivate()) {
            throw new ApiException('Media tidak ditemukan.', 'NOT_FOUND', 404);
        }

        return $this->stream($mediaFile, $disposition);
    }

    private function stream(MediaFile $mediaFile, string $disposition): StreamedResponse
    {
        $disk = Storage::disk($mediaFile->disk);

        if (! $disk->exists($mediaFile->path)) {
            throw new ApiException('File media tidak tersedia.', 'MEDIA_FILE_NOT_AVAILABLE', 404);
        }

        $stream = $disk->readStream($mediaFile->path);

        if ($stream === false) {
            throw new ApiException('File media tidak dapat dibaca.', 'MEDIA_STORAGE_ERROR', 503);
        }

        return response()->stream(function () use ($stream): void {
            fpassthru($stream);

            if (is_resource($stream)) {
                fclose($stream);
            }
        }, 200, [
            'Content-Type' => $mediaFile->mime_type,
            'Content-Length' => (string) $mediaFile->size_bytes,
            'Content-Disposition' => HeaderUtils::makeDisposition($disposition, $this->safeFilename($mediaFile)),
            'X-Content-Type-Options' => 'nosniff',
        ]);
    }

    private function safeFilename(MediaFile $mediaFile): string
    {
        $basename = preg_replace('/[^\w.\- ]+/', '_', $mediaFile->original_name) ?: 'media';
        $basename = trim(str_replace(["\r", "\n", '"'], '_', $basename));

        return $basename !== '' ? $basename : 'media';
    }
}
