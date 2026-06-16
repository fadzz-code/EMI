<?php

namespace App\Models;

use Database\Factories\QuizAttemptFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class QuizAttempt extends Model
{
    /** @use HasFactory<QuizAttemptFactory> */
    use HasFactory, HasUuids;

    protected $fillable = ['class_quiz_id', 'student_id', 'attempt_number', 'status', 'started_at', 'expires_at', 'submitted_at', 'score_points', 'max_points', 'score_percent', 'correct_count', 'incorrect_count', 'unanswered_count', 'submit_idempotency_key_hash'];

    protected function casts(): array
    {
        return [
            'attempt_number' => 'integer',
            'started_at' => 'datetime',
            'expires_at' => 'datetime',
            'submitted_at' => 'datetime',
            'score_points' => 'float',
            'max_points' => 'float',
            'score_percent' => 'float',
            'correct_count' => 'integer',
            'incorrect_count' => 'integer',
            'unanswered_count' => 'integer',
        ];
    }

    public function classQuiz(): BelongsTo
    {
        return $this->belongsTo(ClassQuiz::class);
    }

    public function student(): BelongsTo
    {
        return $this->belongsTo(User::class, 'student_id');
    }

    public function answers(): HasMany
    {
        return $this->hasMany(QuizAnswer::class);
    }
}
