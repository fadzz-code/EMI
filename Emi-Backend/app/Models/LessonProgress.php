<?php

namespace App\Models;

use Database\Factories\LessonProgressFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LessonProgress extends Model
{
    /** @use HasFactory<LessonProgressFactory> */
    use HasFactory, HasUuids;

    protected $table = 'lesson_progress';

    protected $fillable = [
        'student_id',
        'class_lesson_id',
        'status',
        'progress_percent',
        'started_at',
        'completed_at',
        'last_accessed_at',
    ];

    protected function casts(): array
    {
        return [
            'progress_percent' => 'integer',
            'started_at' => 'datetime',
            'completed_at' => 'datetime',
            'last_accessed_at' => 'datetime',
        ];
    }

    public function student(): BelongsTo
    {
        return $this->belongsTo(User::class, 'student_id');
    }

    public function classLesson(): BelongsTo
    {
        return $this->belongsTo(ClassLesson::class);
    }
}
