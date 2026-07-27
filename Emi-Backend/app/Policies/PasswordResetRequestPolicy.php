<?php

namespace App\Policies;

use App\Models\PasswordResetRequest;
use App\Models\User;

class PasswordResetRequestPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->role === 'admin';
    }

    public function view(User $user, PasswordResetRequest $passwordResetRequest): bool
    {
        return $user->role === 'admin';
    }

    public function approve(User $user, PasswordResetRequest $passwordResetRequest): bool
    {
        return $user->role === 'admin';
    }

    public function reject(User $user, PasswordResetRequest $passwordResetRequest): bool
    {
        return $user->role === 'admin';
    }

    public function viewTeacherScope(User $user, ?PasswordResetRequest $passwordResetRequest = null): bool
    {
        if ($user->role !== 'teacher') {
            return false;
        }

        if ($passwordResetRequest === null) {
            return true;
        }

        return $this->targetIsOwnClassStudent($user, $passwordResetRequest);
    }

    public function approveTeacherScope(User $user, PasswordResetRequest $passwordResetRequest): bool
    {
        return $this->viewTeacherScope($user, $passwordResetRequest);
    }

    public function rejectTeacherScope(User $user, PasswordResetRequest $passwordResetRequest): bool
    {
        return $this->viewTeacherScope($user, $passwordResetRequest);
    }

    private function targetIsOwnClassStudent(User $user, PasswordResetRequest $passwordResetRequest): bool
    {
        $target = $passwordResetRequest->relationLoaded('user')
            ? $passwordResetRequest->user
            : $passwordResetRequest->user()->first();

        if (! $target || $target->role !== 'student') {
            return false;
        }

        $teacherClassId = $user->activeClassId();

        return $teacherClassId !== null && $target->activeClassId() === $teacherClassId;
    }
}
