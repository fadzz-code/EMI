<?php

namespace App\Models;

use Database\Factories\QuizTemplateQuestionFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class QuizTemplateQuestion extends Model
{
    /** @use HasFactory<QuizTemplateQuestionFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = ['quiz_template_id', 'question_type', 'question_text', 'image_media_id', 'correct_answer_text', 'use_fuzzy_matching', 'fuzzy_threshold', 'points', 'order_number', 'explanation', 'created_by', 'updated_by'];

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

    public function quizTemplate(): BelongsTo
    {
        return $this->belongsTo(QuizTemplate::class);
    }

    public function options(): HasMany
    {
        return $this->hasMany(QuizTemplateOption::class)->orderBy('order_number');
    }

    public function imageMedia(): BelongsTo
    {
        return $this->belongsTo(MediaFile::class, 'image_media_id');
    }
}
