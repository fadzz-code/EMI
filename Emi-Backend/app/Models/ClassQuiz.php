<?php

namespace App\Models;

use Database\Factories\ClassQuizFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class ClassQuiz extends Model
{
    /** @use HasFactory<ClassQuizFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = ['class_id', 'source_quiz_template_id', 'title', 'description', 'instructions', 'duration_minutes', 'max_attempts', 'show_result', 'open_at', 'close_at', 'status', 'created_by', 'updated_by', 'published_at', 'archived_at'];

    protected function casts(): array
    {
        return [
            'duration_minutes' => 'integer',
            'max_attempts' => 'integer',
            'show_result' => 'boolean',
            'open_at' => 'datetime',
            'close_at' => 'datetime',
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
        return $this->belongsTo(QuizTemplate::class, 'source_quiz_template_id');
    }

    public function questions(): HasMany
    {
        return $this->hasMany(QuizQuestion::class)->orderBy('order_number');
    }

    public function attempts(): HasMany
    {
        return $this->hasMany(QuizAttempt::class);
    }
}
