<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class SpeakingAttempt extends Model
{
    use HasUuids, SoftDeletes;

    protected $fillable = [
        'speaking_exercise_id',
        'student_id',
        'audio_media_id',
        'audio_path',
        'audio_disk',
        'audio_mime_type',
        'audio_size_bytes',
        'audio_duration_seconds',
        'capture_source',
        'target_text_snapshot',
        'status',
        'analysis_status',
        'review_status',
        'ai_engine',
        'ai_model',
        'ai_transcription',
        'ai_score',
        'ai_alignment',
        'ai_raw_response',
        'ai_error',
        'teacher_score',
        'teacher_feedback',
        'reviewed_by_id',
        'reviewed_at',
    ];

    protected function casts(): array
    {
        return [
            'audio_size_bytes' => 'integer',
            'audio_duration_seconds' => 'integer',
            'ai_score' => 'decimal:2',
            'teacher_score' => 'decimal:2',
            'ai_alignment' => 'array',
            'ai_raw_response' => 'array',
            'reviewed_at' => 'datetime',
            'deleted_at' => 'datetime',
        ];
    }

    public function exercise(): BelongsTo
    {
        return $this->belongsTo(SpeakingExercise::class, 'speaking_exercise_id');
    }

    public function student(): BelongsTo
    {
        return $this->belongsTo(User::class, 'student_id');
    }

    public function audioMedia(): BelongsTo
    {
        return $this->belongsTo(MediaFile::class, 'audio_media_id');
    }

    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by_id');
    }

    public function scopeForStudent(Builder $query, User $student): Builder
    {
        return $query->where('student_id', $student->id);
    }
}
