<?php

namespace App\Policies;

use App\Models\ModuleProgress;
use App\Models\User;

class ModuleProgressPolicy
{
    public function view(User $user, ModuleProgress $progress): bool
    {
        return $user->role === 'admin'
            || ($user->role === 'student' && $progress->student_id === $user->id);
    }
}
