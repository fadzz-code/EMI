<?php

namespace App\Http\Resources;

use App\Models\ModuleProgress;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class StudentModuleResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $progress = $this->progress_for_student instanceof ModuleProgress ? $this->progress_for_student : null;

        return [
            'id' => $this->id,
            'title' => $this->title,
            'description' => $this->description,
            'status' => $this->status,
            'sort_order' => $this->sort_order,
            'progress' => $progress ? new ModuleProgressResource($progress) : [
                'status' => 'not_started',
                'progress_percent' => 0,
                'completed_lessons' => 0,
                'total_lessons' => $this->lessons_count ?? 0,
            ],
            'lessons' => ClassLessonResource::collection($this->whenLoaded('lessons')),
        ];
    }
}
