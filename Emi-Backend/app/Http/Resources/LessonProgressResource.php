<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class LessonProgressResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'class_lesson_id' => $this->class_lesson_id,
            'status' => $this->status,
            'progress_percent' => $this->progress_percent,
            'started_at' => $this->started_at?->toISOString(),
            'completed_at' => $this->completed_at?->toISOString(),
            'last_accessed_at' => $this->last_accessed_at?->toISOString(),
        ];
    }
}
