<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class SpeakingExercise extends Model
{
    use HasUuids, SoftDeletes;

    protected $fillable = [
        'title',
        'prompt_text',
        'target_text',
        'target_translation',
        'language_code',
        'difficulty',
        'lesson_id',
        'module_id',
        'classroom_id',
        'created_by_id',
        'status',
        'metadata',
    ];

    protected function casts(): array
    {
        return [
            'metadata' => 'array',
            'deleted_at' => 'datetime',
        ];
    }

    public function lesson(): BelongsTo
    {
        return $this->belongsTo(ClassLesson::class, 'lesson_id');
    }

    public function module(): BelongsTo
    {
        return $this->belongsTo(ClassModule::class, 'module_id');
    }

    public function classroom(): BelongsTo
    {
        return $this->belongsTo(SchoolClass::class, 'classroom_id');
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by_id');
    }

    public function attempts(): HasMany
    {
        return $this->hasMany(SpeakingAttempt::class);
    }

    public function scopePublished(Builder $query): Builder
    {
        return $query->where('status', 'published');
    }
}
