<?php

namespace App\Models;

use Database\Factories\DictionaryEntryFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class DictionaryEntry extends Model
{
    /** @use HasFactory<DictionaryEntryFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = [
        'category_id',
        'code',
        'code_normalized',
        'indonesia',
        'english',
        'mekongga',
        'indonesia_normalized',
        'english_normalized',
        'mekongga_normalized',
        'example_mekongga',
        'example_indonesia',
        'audio_media_id',
        'status',
        'created_by',
        'updated_by',
        'source_import_job_id',
    ];

    protected function casts(): array
    {
        return [
            'deleted_at' => 'datetime',
        ];
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(DictionaryCategory::class, 'category_id');
    }

    public function audioMedia(): BelongsTo
    {
        return $this->belongsTo(MediaFile::class, 'audio_media_id');
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function updater(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    public function sourceImportJob(): BelongsTo
    {
        return $this->belongsTo(DictionaryImportJob::class, 'source_import_job_id');
    }

    public function sentenceExamples(): HasMany
    {
        return $this->hasMany(DictionarySentenceExample::class, 'dictionary_entry_id')->orderBy('created_at')->orderBy('id');
    }

    public function scopeActive(Builder $query): Builder
    {
        return $query->where('status', 'active');
    }
}
