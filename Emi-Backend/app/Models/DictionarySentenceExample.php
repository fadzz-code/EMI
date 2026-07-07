<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class DictionarySentenceExample extends Model
{
    use HasUuids, SoftDeletes;

    protected $fillable = [
        'dictionary_entry_id',
        'code',
        'example_mekongga',
        'example_indonesia',
        'example_mekongga_normalized',
        'example_indonesia_normalized',
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

    public function dictionaryEntry(): BelongsTo
    {
        return $this->belongsTo(DictionaryEntry::class, 'dictionary_entry_id');
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
}
