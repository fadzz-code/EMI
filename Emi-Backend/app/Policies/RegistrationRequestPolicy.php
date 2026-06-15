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
}
