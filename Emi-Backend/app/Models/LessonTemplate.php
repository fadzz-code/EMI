<?php

namespace App\Models;

use Database\Factories\LessonTemplateFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class LessonTemplate extends Model
{
    /** @use HasFactory<LessonTemplateFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'module_template_id',
        'title',
        'description',
        'content_type',
        'content_body',
        'media_id',
        'external_url',
        'sort_order',
        'status',
        'created_by',
        'updated_by',
        'published_at',
        'archived_at',
    ];

    protected function casts(): array
    {
        return [
            'sort_order' => 'integer',
            'published_at' => 'datetime',
            'archived_at' => 'datetime',
            'deleted_at' => 'datetime',
        ];
    }

    public function moduleTemplate(): BelongsTo
    {
        return $this->belongsTo(ModuleTemplate::class);
    }

    public function media(): BelongsTo
    {
        return $this->belongsTo(MediaFile::class);
    }

    public function classLessons(): HasMany
    {
        return $this->hasMany(ClassLesson::class, 'source_lesson_template_id');
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function updater(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    public function scopePublished(Builder $query): Builder
    {
        return $query->where('status', 'published');
    }
}
