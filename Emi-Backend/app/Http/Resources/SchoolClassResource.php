<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SchoolClassResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'school_id' => $this->school_id,
            'name' => $this->name,
            'grade_level' => $this->grade_level,
            'academic_year' => $this->academic_year,
            'status' => $this->status,
            'created_by' => $this->created_by,
            'school' => $this->whenLoaded('school', fn () => new SchoolPublicResource($this->school)),
            'active_teacher_assignment' => $this->whenLoaded('activeTeacherAssignment', fn () => $this->activeTeacherAssignment
                ? new TeacherAssignmentResource($this->activeTeacherAssignment)
                : null),
            'active_students_count' => $this->when(isset($this->active_students_count), $this->active_students_count),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
