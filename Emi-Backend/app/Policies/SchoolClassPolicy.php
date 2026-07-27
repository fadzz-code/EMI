<?php

namespace App\Policies;

use App\Models\SchoolClass;
use App\Models\User;

class SchoolClassPolicy
{
    public function viewAny(User $user): bool
    {
        return in_array($user->role, ['admin', 'teacher', 'student'], true);
    }

    public function view(User $user, SchoolClass $schoolClass): bool
    {
        if ($user->role === 'admin') {
            return true;
        }

        return $user->activeClassId() === $schoolClass->id;
    }

    public function create(User $user): bool
    {
        return $user->role === 'admin';
    }

    public function update(User $user, SchoolClass $schoolClass): bool
    {
        return $user->role === 'admin';
    }

    public function delete(User $user, SchoolClass $schoolClass): bool
    {
        return $user->role === 'admin';
    }

    public function forceDelete(User $user, SchoolClass $schoolClass): bool
    {
        return $user->role === 'admin';
    }

    public function assignTeacher(User $user, SchoolClass $schoolClass): bool
    {
        return $user->role === 'admin';
    }

    public function assignStudent(User $user, SchoolClass $schoolClass): bool
    {
        return $user->role === 'admin';
    }

    public function viewStudents(User $user, SchoolClass $schoolClass): bool
    {
        if ($user->role === 'admin') {
            return true;
        }

        if ($user->role !== 'teacher') {
            return false;
        }

        return $user->activeClassId() === $schoolClass->id;
    }
}
