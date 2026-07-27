<?php

namespace App\Http\Resources;

use App\Services\MediaAccessService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $teacherAssignment = $this->resource->relationLoaded('activeTeacherClassAssignment')
            ? $this->activeTeacherClassAssignment
            : null;
        $studentMembership = $this->resource->relationLoaded('activeStudentClassMembership')
            ? $this->activeStudentClassMembership
            : null;
        $activeRelation = $this->role === 'teacher' ? $teacherAssignment : $studentMembership;
        $schoolClass = $activeRelation?->relationLoaded('schoolClass') ? $activeRelation->schoolClass : null;
        $school = $schoolClass?->relationLoaded('school') ? $schoolClass->school : null;
        $avatar = $this->resource->relationLoaded('avatarMedia') ? $this->avatarMedia : null;

        return [
            'id' => $this->id,
            'full_name' => $this->full_name,
            'email' => $this->email,
            'phone' => $this->phone,
            'avatar' => $avatar ? [
                'id' => $avatar->id,
                'url' => app(MediaAccessService::class)->publicUrl($avatar),
            ] : null,
            'role' => $this->role,
            'status' => $this->status,
            'password_must_change' => (bool) $this->password_must_change,
            'active_school' => $school ? new SchoolPublicResource($school) : null,
            'active_class' => $schoolClass ? new SchoolClassPublicResource($schoolClass) : null,
            'active_assignment' => $this->role === 'teacher' && $teacherAssignment ? [
                'id' => $teacherAssignment->id,
                'class_id' => $teacherAssignment->class_id,
                'is_active' => $teacherAssignment->is_active,
                'assigned_at' => $teacherAssignment->assigned_at?->toISOString(),
            ] : null,
            'active_membership' => $this->role === 'student' && $studentMembership ? [
                'id' => $studentMembership->id,
                'class_id' => $studentMembership->class_id,
                'is_active' => $studentMembership->is_active,
                'joined_at' => $studentMembership->joined_at?->toISOString(),
            ] : null,
        ];
    }
}
