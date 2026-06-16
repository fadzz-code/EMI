<?php

namespace App\Models;

use Database\Factories\ClassModuleFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class ClassModule extends Model
{
    /** @use HasFactory<ClassModuleFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'class_id',
        'source_module_template_id',
        'title',
        'description',
        'status',
        'sort_order',
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

    public function schoolClass(): BelongsTo
    {
        return $this->belongsTo(SchoolClass::class, 'class_id');
    }

    public function sourceTemplate(): BelongsTo
    {
        return $this->belongsTo(ModuleTemplate::class, 'source_module_template_id');
    }

    public function lessons(): HasMany
    {
        return $this->hasMany(ClassLesson::class)->orderBy('sort_order');
    }

    public function progress(): HasMany
    {
        return $this->hasMany(ModuleProgress::class);
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
