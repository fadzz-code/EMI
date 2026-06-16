<?php

namespace App\Models;

use Database\Factories\QuizTemplateFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class QuizTemplate extends Model
{
    /** @use HasFactory<QuizTemplateFactory> */
    use HasFactory, HasUuids, SoftDeletes;

    protected $fillable = ['title', 'description', 'instructions', 'duration_minutes', 'max_attempts', 'show_result', 'status', 'created_by', 'updated_by', 'published_at', 'archived_at'];

    protected function casts(): array
    {
        return [
            'duration_minutes' => 'integer',
            'max_attempts' => 'integer',
            'show_result' => 'boolean',
            'published_at' => 'datetime',
            'archived_at' => 'datetime',
            'deleted_at' => 'datetime',
        ];
    }

    public function questions(): HasMany
    {
        return $this->hasMany(QuizTemplateQuestion::class)->orderBy('order_number');
    }

    public function classQuizzes(): HasMany
    {
        return $this->hasMany(ClassQuiz::class, 'source_quiz_template_id');
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function updater(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by');
    }
}
