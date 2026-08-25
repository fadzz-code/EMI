<?php

namespace App\Services;

use App\Models\AdminCultureItem;
use App\Models\ClassCultureItem;
use App\Models\ClassLesson;
use App\Models\CultureTemplateItem;
use App\Models\DictionaryEntry;
use App\Models\LessonTemplate;
use App\Models\MediaFile;
use App\Models\QuizQuestion;
use App\Models\QuizTemplateQuestion;
use App\Models\SpeakingAttempt;
use App\Models\SystemSetting;
use App\Models\User;

class MediaUsageService
{
    public function isInUse(MediaFile $mediaFile): bool
    {
        return User::query()->where('avatar_media_id', $mediaFile->id)->exists()
            || DictionaryEntry::query()->where('audio_media_id', $mediaFile->id)->exists()
            || LessonTemplate::query()->where('media_id', $mediaFile->id)->exists()
            || ClassLesson::query()->where('media_id', $mediaFile->id)->exists()
            || QuizTemplateQuestion::query()->where('image_media_id', $mediaFile->id)->exists()
            || QuizQuestion::query()->where('image_media_id', $mediaFile->id)->exists()
            || AdminCultureItem::query()->where('media_id', $mediaFile->id)->exists()
            || ClassCultureItem::query()->where(fn ($query) => $query->where('media_id', $mediaFile->id)->orWhere('thumbnail_media_id', $mediaFile->id))->exists()
            || CultureTemplateItem::query()->where(fn ($query) => $query->where('media_id', $mediaFile->id)->orWhere('thumbnail_media_id', $mediaFile->id))->exists()
            || SpeakingAttempt::query()->where('audio_media_id', $mediaFile->id)->exists()
            || SystemSetting::query()->where('key', 'banner')->where('value->image_media_id', $mediaFile->id)->exists();
    }
}
