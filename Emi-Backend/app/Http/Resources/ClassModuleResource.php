<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ClassModuleResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'class_id' => $this->class_id,
            'source_module_template_id' => $this->source_module_template_id,
            'title' => $this->title,
            'description' => $this->description,
            'status' => $this->status,
            'sort_order' => $this->sort_order,
            'created_by' => $this->created_by,
            'updated_by' => $this->updated_by,
            'published_at' => $this->published_at?->toISOString(),
            'archived_at' => $this->archived_at?->toISOString(),
            'lessons' => ClassLessonResource::collection($this->whenLoaded('lessons')),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
