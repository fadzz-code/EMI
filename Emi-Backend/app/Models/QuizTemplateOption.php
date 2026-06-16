<?php

namespace App\Models;

use Database\Factories\QuizTemplateOptionFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class QuizTemplateOption extends Model
{
    /** @use HasFactory<QuizTemplateOptionFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = ['quiz_template_question_id', 'option_text', 'is_correct', 'order_number'];

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
        return $this->belongsTo(QuizTemplateQuestion::class, 'quiz_template_question_id');
    }
}
