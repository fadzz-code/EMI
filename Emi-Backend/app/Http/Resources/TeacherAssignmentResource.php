<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TeacherAssignmentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'teacher_id' => $this->teacher_id,
            'class_id' => $this->class_id,
            'is_active' => $this->is_active,
            'assigned_at' => $this->assigned_at?->toISOString(),
            'ended_at' => $this->ended_at?->toISOString(),
            'teacher' => $this->whenLoaded('teacher', fn () => [
                'id' => $this->teacher->id,
                'full_name' => $this->teacher->full_name,
                'email' => $this->teacher->email,
                'status' => $this->teacher->status,
            ]),
        ];
    }
}
