<?php

namespace App\Models;

use Database\Factories\QuizAnswerFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class QuizAnswer extends Model
{
    /** @use HasFactory<QuizAnswerFactory> */
    use HasFactory, HasUuids;

    protected $fillable = ['quiz_attempt_id', 'quiz_question_id', 'selected_option_id', 'answer_text', 'normalized_answer', 'is_correct', 'similarity_score', 'awarded_points', 'max_points', 'answered_at'];

    protected function casts(): array
    {
        return [
            'is_correct' => 'boolean',
            'similarity_score' => 'float',
            'awarded_points' => 'float',
            'max_points' => 'float',
            'answered_at' => 'datetime',
        ];
    }

    public function attempt(): BelongsTo
    {
        return $this->belongsTo(QuizAttempt::class, 'quiz_attempt_id');
    }

    public function question(): BelongsTo
    {
        return $this->belongsTo(QuizQuestion::class, 'quiz_question_id');
    }

    public function selectedOption(): BelongsTo
    {
        return $this->belongsTo(QuizOption::class, 'selected_option_id');
    }
}
