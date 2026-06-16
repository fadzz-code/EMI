<?php

namespace App\Models;

use Database\Factories\DictionaryImportErrorFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DictionaryImportError extends Model
{
    /** @use HasFactory<DictionaryImportErrorFactory> */
    use HasFactory, HasUuids;

    public $timestamps = false;

    protected $fillable = [
        'import_job_id',
        'row_number',
        'field',
        'code',
        'message',
        'raw_data',
        'created_at',
    ];

    protected function casts(): array
    {
        return [
            'raw_data' => 'array',
            'row_number' => 'integer',
            'created_at' => 'datetime',
        ];
    }

    public function importJob(): BelongsTo
    {
        return $this->belongsTo(DictionaryImportJob::class, 'import_job_id');
    }
}
