<?php

namespace App\Services;

use App\Models\DictionaryEntry;
use App\Models\MediaFile;
use App\Models\User;

class MediaUsageService
{
    public function isInUse(MediaFile $mediaFile): bool
    {
        return User::query()->where('avatar_media_id', $mediaFile->id)->exists()
            || DictionaryEntry::query()->where('audio_media_id', $mediaFile->id)->exists();
    }
}
