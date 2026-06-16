<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class QuizAttemptResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $showResult = (bool) $this->resource->getAttribute('show_result_fields')
            || $request->user()?->role !== 'student'
            || ($this->classQuiz && $this->classQuiz->show_result);

        $this->whenLoaded('answers', fn () => $this->answers->each->setAttribute('show_result_fields', $showResult));

        return [
            'id' => $this->id,
            'class_quiz_id' => $this->class_quiz_id,
            'student_id' => $this->student_id,
            'attempt_number' => $this->attempt_number,
            'status' => $this->status,
            'started_at' => $this->started_at?->toISOString(),
            'expires_at' => $this->expires_at?->toISOString(),
            'submitted_at' => $this->submitted_at?->toISOString(),
            'score_points' => $this->when($showResult, $this->score_points),
            'max_points' => $this->when($showResult, $this->max_points),
            'score_percent' => $this->when($showResult, $this->score_percent),
            'correct_count' => $this->when($showResult, $this->correct_count),
            'incorrect_count' => $this->when($showResult, $this->incorrect_count),
            'unanswered_count' => $this->when($showResult, $this->unanswered_count),
            'class_quiz' => new StudentQuizResource($this->whenLoaded('classQuiz')),
            'answers' => QuizAnswerResource::collection($this->whenLoaded('answers')),
        ];
    }
}
