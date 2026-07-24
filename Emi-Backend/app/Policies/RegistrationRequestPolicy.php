<?php

namespace App\Policies;

use App\Models\RegistrationRequest;
use App\Models\User;

class RegistrationRequestPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->role === 'admin';
    }

    public function view(User $user, RegistrationRequest $registrationRequest): bool
    {
        return $user->role === 'admin';
    }

    public function approve(User $user, RegistrationRequest $registrationRequest): bool
    {
        return $user->role === 'admin';
    }

    public function reject(User $user, RegistrationRequest $registrationRequest): bool
    {
        return $user->role === 'admin';
    }

    public function viewTeacherScope(User $user, ?RegistrationRequest $registrationRequest = null): bool
    {
        if ($user->role !== 'teacher') {
            return false;
        }

        if ($registrationRequest === null) {
            return true;
        }

        return $registrationRequest->requested_role === 'student' &&
               $registrationRequest->schoolClass()
                   ->whereHas('teacherAssignments', function ($q) use ($user) {
                       $q->where('teacher_id', $user->id)
                           ->where('is_active', true);
                   })
                   ->exists();
    }

    public function approveTeacherScope(User $user, RegistrationRequest $registrationRequest): bool
    {
        return $this->viewTeacherScope($user, $registrationRequest);
    }
}
