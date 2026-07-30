<?php

namespace App\Models;

use Database\Factories\DictionaryImportJobFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class DictionaryImportJob extends Model
{
    /** @use HasFactory<DictionaryImportJobFactory> */
    use HasFactory, HasUuids;

    protected $fillable = [
        'uploaded_by',
        'status',
        'duplicate_strategy',
        'import_type',
        'source_format',
        'csv_disk',
        'csv_path',
        'csv_original_name',
        'csv_size_bytes',
        'csv_checksum_sha256',
        'audio_zip_disk',
        'audio_zip_path',
        'audio_zip_original_name',
        'audio_zip_size_bytes',
        'audio_zip_checksum_sha256',
        'total_rows',
        'valid_rows',
        'invalid_rows',
        'inserted_rows',
        'updated_rows',
        'skipped_rows',
        'warning_count',
        'summary',
        'started_at',
        'completed_at',
        'failed_at',
        'failure_code',
        'failure_message',
    ];

    protected function casts(): array
    {
        return [
            'summary' => 'array',
            'total_rows' => 'integer',
            'valid_rows' => 'integer',
            'invalid_rows' => 'integer',
            'inserted_rows' => 'integer',
            'updated_rows' => 'integer',
            'skipped_rows' => 'integer',
            'warning_count' => 'integer',
            'started_at' => 'datetime',
            'completed_at' => 'datetime',
            'failed_at' => 'datetime',
        ];
    }

    public function uploader(): BelongsTo
    {
        return $this->belongsTo(User::class, 'uploaded_by');
    }

    public function errors(): HasMany
    {
        return $this->hasMany(DictionaryImportError::class, 'import_job_id');
    }

    public function entries(): HasMany
    {
        return $this->hasMany(DictionaryEntry::class, 'source_import_job_id');
    }
}
