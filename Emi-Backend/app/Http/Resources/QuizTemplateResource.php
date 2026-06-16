<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class QuizTemplateResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'description' => $this->description,
            'instructions' => $this->instructions,
            'duration_minutes' => $this->duration_minutes,
            'max_attempts' => $this->max_attempts,
            'show_result' => $this->show_result,
            'status' => $this->status,
            'created_by' => $this->created_by,
            'updated_by' => $this->updated_by,
            'published_at' => $this->published_at?->toISOString(),
            'archived_at' => $this->archived_at?->toISOString(),
            'questions_count' => $this->whenCounted('questions'),
            'questions' => QuizTemplateQuestionResource::collection($this->whenLoaded('questions')),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
