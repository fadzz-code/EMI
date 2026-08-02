<?php

namespace App\Policies;

use App\Models\User;

class UserPolicy
{
    public function viewAny(User $user): bool
    {
        return in_array($user->role, ['admin', 'teacher'], true);
    }

    public function view(User $user, User $target): bool
    {
        if ($user->role === 'admin') {
            return true;
        }

        if ($user->role !== 'teacher' || $target->role !== 'student') {
            return false;
        }

        return $target->activeStudentClassMembership?->class_id === $user->activeClassId();
    }

    public function update(User $user, User $target): bool
    {
        return $user->role === 'admin';
    }

    public function updateStatus(User $user, User $target): bool
    {
        return $user->role === 'admin';
    }

    public function forcePasswordReset(User $user, User $target): bool
    {
        return $user->role === 'admin';
    }

    public function forceDelete(User $user, User $target): bool
    {
        return $user->role === 'admin'
            && $user->id !== $target->id
            && in_array($target->role, ['teacher', 'student'], true);
    }
}
