<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class StudentQuizResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $hasActiveAttempt = (int) ($this->active_attempts_count ?? 0) > 0;
        $showResult = $request->user()?->role !== 'student' || $this->show_result;
        $result = fn (string $prefix): ?array => $showResult && $this->{$prefix.'_score_percent'} !== null ? [
            'score_points' => $prefix === 'latest' && $this->latest_score_points !== null ? (float) $this->latest_score_points : null,
            'max_points' => $prefix === 'latest' && $this->latest_max_points !== null ? (float) $this->latest_max_points : null,
            'score_percent' => (float) $this->{$prefix.'_score_percent'},
            'submitted_at' => $prefix === 'latest' ? $this->latest_submitted_at : null,
        ] : null;

        return [
            'id' => $this->id,
            'class_id' => $this->class_id,
            'title' => $this->title,
            'description' => $this->description,
            'instructions' => $this->instructions,
            'duration_minutes' => $this->duration_minutes,
            'max_attempts' => $this->max_attempts,
            'show_result' => $this->show_result,
            'open_at' => $this->open_at?->toISOString(),
            'close_at' => $this->close_at?->toISOString(),
            'questions_count' => $this->whenCounted('questions'),
            'attempts_count' => $this->whenCounted('attempts'),
            'used_attempts' => $this->whenCounted('attempts'),
            'submitted_attempts_count' => (int) ($this->submitted_attempts_count ?? 0),
            'expired_attempts_count' => (int) ($this->expired_attempts_count ?? 0),
            'finished_attempts_count' => (int) ($this->finished_attempts_count ?? 0),
            'remaining_attempts' => $this->max_attempts !== null ? max($this->max_attempts - (int) ($this->attempts_count ?? 0), 0) : null,
            'attempt_limit_reached' => ! $hasActiveAttempt && $this->max_attempts !== null && (int) ($this->attempts_count ?? 0) >= $this->max_attempts,
            'has_active_attempt' => $hasActiveAttempt,
            'active_attempt' => $hasActiveAttempt ? [
                'id' => $this->active_attempt_id,
                'attempt_number' => (int) $this->active_attempt_number,
                'status' => $this->active_attempt_status,
                'started_at' => $this->active_attempt_started_at,
                'expires_at' => $this->active_attempt_expires_at,
            ] : null,
            'can_start' => $hasActiveAttempt || $this->max_attempts === null || (int) ($this->attempts_count ?? 0) < $this->max_attempts,
            'best_result' => $result('best'),
            'latest_result' => $result('latest'),
            'latest_score_points' => $showResult && $this->latest_score_points !== null ? (float) $this->latest_score_points : null,
            'latest_max_points' => $showResult && $this->latest_max_points !== null ? (float) $this->latest_max_points : null,
            'latest_score_normalized' => $showResult && $this->latest_score_percent !== null ? (float) $this->latest_score_percent : null,
            'latest_score_percent' => $showResult && $this->latest_score_percent !== null ? (float) $this->latest_score_percent : null,
            'best_score_percent' => $showResult && $this->best_score_percent !== null ? (float) $this->best_score_percent : null,
            'latest_submitted_at' => $this->latest_submitted_at,
            'questions' => QuizQuestionResource::collection($this->whenLoaded('questions')),
        ];
    }
}
