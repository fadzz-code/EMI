<?php

namespace App\Models;

use Database\Factories\ModuleProgressFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ModuleProgress extends Model
{
    /** @use HasFactory<ModuleProgressFactory> */
    use HasFactory, HasUuids;

    protected $table = 'module_progress';

    protected $fillable = [
        'student_id',
        'class_module_id',
        'status',
        'progress_percent',
        'completed_lessons',
        'total_lessons',
        'started_at',
        'completed_at',
        'last_calculated_at',
    ];

    protected function casts(): array
    {
        return [
            'progress_percent' => 'integer',
            'completed_lessons' => 'integer',
            'total_lessons' => 'integer',
            'started_at' => 'datetime',
            'completed_at' => 'datetime',
            'last_calculated_at' => 'datetime',
        ];
    }

    public function student(): BelongsTo
    {
        return $this->belongsTo(User::class, 'student_id');
    }

    public function classModule(): BelongsTo
    {
        return $this->belongsTo(ClassModule::class);
    }
}
