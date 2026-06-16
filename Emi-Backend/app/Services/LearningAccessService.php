<?php

namespace App\Services;

use App\Models\ClassLesson;
use App\Models\ClassModule;
use App\Models\SchoolClass;
use App\Models\User;

class LearningAccessService
{
    public function canManageClass(User $user, SchoolClass $class): bool
    {
        if ($user->role === 'admin') {
            return true;
        }

        return $user->role === 'teacher'
            && $user->activeTeacherClassAssignment?->class_id === $class->id;
    }

    public function canManageModule(User $user, ClassModule $module): bool
    {
        $module->loadMissing('schoolClass');

        return $this->canManageClass($user, $module->schoolClass);
    }

    public function canManageLesson(User $user, ClassLesson $lesson): bool
    {
        $lesson->loadMissing('classModule.schoolClass');

        return $this->canManageClass($user, $lesson->classModule->schoolClass);
    }

    public function studentClassId(User $user): ?string
    {
        return $user->role === 'student'
            ? $user->activeStudentClassMembership?->class_id
            : null;
    }

    public function studentCanAccessModule(User $user, ClassModule $module): bool
    {
        $module->loadMissing('schoolClass.school');

        return $user->role === 'student'
            && $module->status === 'published'
            && $module->schoolClass->status === 'active'
            && $module->schoolClass->school?->status === 'active'
            && $this->studentClassId($user) === $module->class_id;
    }

    public function studentCanAccessLesson(User $user, ClassLesson $lesson): bool
    {
        $lesson->loadMissing('classModule.schoolClass.school');

        return $lesson->status === 'published'
            && $this->studentCanAccessModule($user, $lesson->classModule);
    }
}
