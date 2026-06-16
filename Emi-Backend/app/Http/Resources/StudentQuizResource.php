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
            'questions' => QuizQuestionResource::collection($this->whenLoaded('questions')),
        ];
    }
}
