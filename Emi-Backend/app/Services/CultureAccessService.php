<?php

namespace App\Services;

use App\Models\ClassCultureItem;
use App\Models\SchoolClass;
use App\Models\User;

class CultureAccessService
{
    public function canManageClass(User $user, SchoolClass $class): bool
    {
        if ($user->role === 'admin') {
            return true;
        }

        $class->loadMissing('school');

        return $user->role === 'teacher'
            && $class->status === 'active'
            && $class->school?->status === 'active'
            && $user->teacherClassAssignments()->where('class_id', $class->id)->where('is_active', true)->exists();
    }

    public function canManageItem(User $user, ClassCultureItem $item): bool
    {
        $item->loadMissing('schoolClass');

        return $this->canManageClass($user, $item->schoolClass);
    }

    public function studentClassIds(User $user): array
    {
        if ($user->role !== 'student') {
            return [];
        }

        return $user->studentClassMemberships()->where('is_active', true)->pluck('class_id')->all();
    }

    public function studentClassId(User $user): ?string
    {
        return $this->studentClassIds($user)[0] ?? null;
    }

    public function studentCanAccessItem(User $user, ClassCultureItem $item): bool
    {
        $item->loadMissing('schoolClass.school');

        return $user->role === 'student'
            && $item->status === 'published'
            && $item->schoolClass->status === 'active'
            && $item->schoolClass->school?->status === 'active'
            && in_array($item->class_id, $this->studentClassIds($user), true);
    }
}
