<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class StudentQuizResource extends JsonResource
{
    public function toArray(Request $request): array
    {
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
            'remaining_attempts' => $this->max_attempts !== null ? max($this->max_attempts - (int) ($this->attempts_count ?? 0), 0) : null,
            'attempt_limit_reached' => $this->max_attempts !== null && (int) ($this->attempts_count ?? 0) >= $this->max_attempts,
            'can_start' => $this->max_attempts === null || (int) ($this->attempts_count ?? 0) < $this->max_attempts,
            'latest_score_points' => $this->latest_score_points !== null ? (float) $this->latest_score_points : null,
            'latest_max_points' => $this->latest_max_points !== null ? (float) $this->latest_max_points : null,
            'latest_score_normalized' => $this->latest_score_percent !== null ? (float) $this->latest_score_percent : null,
            'latest_score_percent' => $this->latest_score_percent !== null ? (float) $this->latest_score_percent : null,
            'best_score_percent' => $this->best_score_percent !== null ? (float) $this->best_score_percent : null,
            'latest_submitted_at' => $this->latest_submitted_at,
            'questions' => QuizQuestionResource::collection($this->whenLoaded('questions')),
        ];
    }
}
