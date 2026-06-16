<?php

namespace App\Models;

use Database\Factories\ModuleTemplateFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class ModuleTemplate extends Model
{
    /** @use HasFactory<ModuleTemplateFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'title',
        'description',
        'status',
        'created_by',
        'updated_by',
        'published_at',
        'archived_at',
    ];

    protected function casts(): array
    {
        return [
            'published_at' => 'datetime',
            'archived_at' => 'datetime',
            'deleted_at' => 'datetime',
        ];
    }

    public function lessons(): HasMany
    {
        return $this->hasMany(LessonTemplate::class)->orderBy('sort_order');
    }

    public function classModules(): HasMany
    {
        return $this->hasMany(ClassModule::class, 'source_module_template_id');
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function updater(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    public function scopeDraft(Builder $query): Builder
    {
        return $query->where('status', 'draft');
    }

    public function scopePublished(Builder $query): Builder
    {
        return $query->where('status', 'published');
    }

    public function scopeArchived(Builder $query): Builder
    {
        return $query->where('status', 'archived');
    }
}
