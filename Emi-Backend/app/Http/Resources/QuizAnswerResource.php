<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class QuizAnswerResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $showResult = (bool) $this->resource->getAttribute('show_result_fields');

        return [
            'id' => $this->id,
            'quiz_attempt_id' => $this->quiz_attempt_id,
            'quiz_question_id' => $this->quiz_question_id,
            'selected_option_id' => $this->selected_option_id,
            'answer_text' => $this->answer_text,
            'is_correct' => $this->when($showResult, $this->is_correct),
            'similarity_score' => $this->when($showResult, $this->similarity_score),
            'awarded_points' => $this->when($showResult, $this->awarded_points),
            'max_points' => $this->when($showResult, $this->max_points),
            'answered_at' => $this->answered_at?->toISOString(),
        ];
    }
}
