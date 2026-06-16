<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ModuleProgressResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'class_module_id' => $this->class_module_id,
            'status' => $this->status,
            'progress_percent' => $this->progress_percent,
            'completed_lessons' => $this->completed_lessons,
            'total_lessons' => $this->total_lessons,
            'started_at' => $this->started_at?->toISOString(),
            'completed_at' => $this->completed_at?->toISOString(),
            'last_calculated_at' => $this->last_calculated_at?->toISOString(),
        ];
    }
}
