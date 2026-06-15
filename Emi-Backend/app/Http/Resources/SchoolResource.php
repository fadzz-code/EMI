<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SchoolResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'address' => $this->address,
            'phone' => $this->phone,
            'status' => $this->status,
            'created_by' => $this->created_by,
            'classes_count' => $this->whenCounted('classes'),
            'active_classes_count' => $this->when(isset($this->active_classes_count), $this->active_classes_count),
            'active_teachers_count' => $this->when(isset($this->active_teachers_count), $this->active_teachers_count),
            'active_students_count' => $this->when(isset($this->active_students_count), $this->active_students_count),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
