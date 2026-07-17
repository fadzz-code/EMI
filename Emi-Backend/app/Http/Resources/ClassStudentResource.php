<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ClassStudentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $student = $this->student;

        return [
            'membership_id' => $this->id,
            'joined_at' => $this->joined_at?->toISOString(),
            'student' => [
                'id' => $student->id,
                'full_name' => $student->full_name,
                'email' => $student->email,
                'role' => $student->role,
                'status' => $student->status,
            ],
        ];
    }
}
