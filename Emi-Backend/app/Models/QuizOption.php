<?php

namespace App\Models;

use Database\Factories\QuizOptionFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class QuizOption extends Model
{
    /** @use HasFactory<QuizOptionFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = ['quiz_question_id', 'source_quiz_template_option_id', 'option_text', 'is_correct', 'order_number'];

    protected function casts(): array
    {
        return [
            'is_correct' => 'boolean',
            'order_number' => 'integer',
            'deleted_at' => 'datetime',
        ];
    }

    public function question(): BelongsTo
    {
        return $this->belongsTo(QuizQuestion::class, 'quiz_question_id');
    }
}
