<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\MediaFile;

class DictionaryAudioService
{
    public function validateAudio(?string $mediaId): ?MediaFile
    {
        if ($mediaId === null) {
            return null;
        }

        $media = MediaFile::query()->active()->findOrFail($mediaId);
        $allowedMimes = config('media.allowed_mimes.audio', []);

        if ($media->purpose !== 'audio' || $media->visibility !== 'public' || ! in_array($media->mime_type, $allowedMimes, true)) {
            throw new ApiException('Media audio kamus tidak valid.', 'INVALID_DICTIONARY_AUDIO', 422, [
                'audio_media_id' => ['Media harus berupa audio publik yang aktif.'],
            ]);
        }

        return $media;
    }
}
