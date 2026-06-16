<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\MediaFile;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class MediaDeletionService
{
    public function __construct(
        private readonly AuditLogService $auditLogService,
        private readonly MediaUsageService $mediaUsageService,
    ) {}

    public function delete(MediaFile $mediaFile, User $actor, Request $request): MediaFile
    {
        return $this->deleteInternal($mediaFile, $actor, $request, true);
    }

    public function deleteUnused(MediaFile $mediaFile, User $actor, Request $request): MediaFile
    {
        return $this->deleteInternal($mediaFile, $actor, $request, false);
    }

    private function deleteInternal(MediaFile $mediaFile, User $actor, Request $request, bool $failWhenInUse): MediaFile
    {
        return DB::transaction(function () use ($mediaFile, $actor, $request, $failWhenInUse) {
            $mediaFile = MediaFile::query()->whereKey($mediaFile->id)->lockForUpdate()->firstOrFail();

            if ($failWhenInUse && $this->mediaUsageService->isInUse($mediaFile)) {
                throw new ApiException('Media masih digunakan dan tidak dapat dihapus.', 'MEDIA_IN_USE', 409);
            }

            if (! $failWhenInUse && $this->mediaUsageService->isInUse($mediaFile)) {
                return $mediaFile;
            }

            $disk = Storage::disk($mediaFile->disk);

            if (! $disk->exists($mediaFile->path) || ! $disk->delete($mediaFile->path)) {
                throw new ApiException('Media gagal dihapus dari storage.', 'MEDIA_STORAGE_ERROR', 503);
            }

            $mediaFile->forceFill(['deleted_by' => $actor->id])->save();
            $mediaFile->delete();

            $this->auditLogService->record('media.deleted', $mediaFile, $actor, ['visibility' => $mediaFile->visibility], null, [
                'purpose' => $mediaFile->purpose,
            ], $request);

            return $mediaFile;
        });
    }
}
