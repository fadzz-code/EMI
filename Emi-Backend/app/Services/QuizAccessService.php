<?php

namespace App\Services;

use App\Models\ClassQuiz;
use App\Models\SchoolClass;
use App\Models\User;

class QuizAccessService
{
    public function canManageClass(User $user, SchoolClass $class): bool
    {
        if ($user->role === 'admin') {
            return true;
        }

        return $user->role === 'teacher'
            && $user->activeTeacherClassAssignment?->class_id === $class->id;
    }

    public function canManageQuiz(User $user, ClassQuiz $quiz): bool
    {
        $quiz->loadMissing('schoolClass');

        return $this->canManageClass($user, $quiz->schoolClass);
    }

    public function studentClassId(User $user): ?string
    {
        return $user->role === 'student'
            ? $user->activeStudentClassMembership?->class_id
            : null;
    }

    public function studentCanAccessQuiz(User $user, ClassQuiz $quiz): bool
    {
        $quiz->loadMissing('schoolClass.school');

        return $user->role === 'student'
            && $quiz->status === 'published'
            && $quiz->schoolClass->status === 'active'
            && $quiz->schoolClass->school?->status === 'active'
            && $this->studentClassId($user) === $quiz->class_id;
    }
}
