<?php

namespace App\Policies;

use App\Models\School;
use App\Models\User;

class SchoolPolicy
{
    public function viewAny(User $user): bool
    {
        return in_array($user->role, ['admin', 'teacher', 'student'], true);
    }

    public function view(User $user, School $school): bool
    {
        if ($user->role === 'admin') {
            return true;
        }

        return $user->activeSchoolId() === $school->id;
    }

    public function create(User $user): bool
    {
        return $user->role === 'admin';
    }

    public function update(User $user, School $school): bool
    {
        return $user->role === 'admin';
    }

    public function delete(User $user, School $school): bool
    {
        return $user->role === 'admin';
    }

    public function forceDelete(User $user, School $school): bool
    {
        return $user->role === 'admin';
    }
}
