<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class StudentMembershipResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'student_id' => $this->student_id,
            'class_id' => $this->class_id,
            'is_active' => $this->is_active,
            'joined_at' => $this->joined_at?->toISOString(),
            'ended_at' => $this->ended_at?->toISOString(),
            'student' => $this->whenLoaded('student', fn () => [
                'id' => $this->student->id,
                'full_name' => $this->student->full_name,
                'email' => $this->student->email,
                'status' => $this->student->status,
            ]),
        ];
    }
}
