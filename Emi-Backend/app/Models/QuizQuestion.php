<?php

namespace App\Models;

use Database\Factories\QuizQuestionFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class QuizQuestion extends Model
{
    /** @use HasFactory<QuizQuestionFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = ['class_quiz_id', 'source_quiz_template_question_id', 'question_type', 'question_text', 'image_media_id', 'correct_answer_text', 'use_fuzzy_matching', 'fuzzy_threshold', 'points', 'order_number', 'explanation', 'created_by', 'updated_by'];

    protected function casts(): array
    {
        return [
            'use_fuzzy_matching' => 'boolean',
            'fuzzy_threshold' => 'integer',
            'points' => 'integer',
            'order_number' => 'integer',
            'deleted_at' => 'datetime',
        ];
    }

    public function classQuiz(): BelongsTo
    {
        return $this->belongsTo(ClassQuiz::class);
    }

    public function sourceQuestion(): BelongsTo
    {
        return $this->belongsTo(QuizTemplateQuestion::class, 'source_quiz_template_question_id');
    }

    public function options(): HasMany
    {
        return $this->hasMany(QuizOption::class)->orderBy('order_number');
    }

    public function answers(): HasMany
    {
        return $this->hasMany(QuizAnswer::class);
    }

    public function imageMedia(): BelongsTo
    {
        return $this->belongsTo(MediaFile::class, 'image_media_id');
    }
}
