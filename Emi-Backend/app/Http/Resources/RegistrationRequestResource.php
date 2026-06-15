<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RegistrationRequestResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'requested_role' => $this->requested_role,
            'status' => $this->status,
            'review_note' => $this->review_note,
            'reviewed_at' => $this->reviewed_at?->toISOString(),
            'created_at' => $this->created_at?->toISOString(),
            'user' => $this->whenLoaded('user', fn () => [
                'id' => $this->user->id,
                'full_name' => $this->user->full_name,
                'email' => $this->user->email,
                'role' => $this->user->role,
                'status' => $this->user->status,
            ]),
            'school' => $this->whenLoaded('school', fn () => new SchoolPublicResource($this->school)),
            'school_class' => $this->whenLoaded('schoolClass', fn () => new SchoolClassPublicResource($this->schoolClass)),
            'reviewed_by' => $this->whenLoaded('reviewedBy', fn () => $this->reviewedBy ? [
                'id' => $this->reviewedBy->id,
                'full_name' => $this->reviewedBy->full_name,
                'email' => $this->reviewedBy->email,
            ] : null),
        ];
    }
}
