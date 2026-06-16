<?php

namespace App\Policies;

use App\Models\LessonTemplate;
use App\Models\User;

class LessonTemplatePolicy
{
    public function viewAny(User $user): bool
    {
        return $user->role === 'admin';
    }

    public function view(User $user, LessonTemplate $lesson): bool
    {
        return $user->role === 'admin';
    }

    public function create(User $user): bool
    {
        return $user->role === 'admin';
    }

    public function update(User $user, LessonTemplate $lesson): bool
    {
        return $user->role === 'admin';
    }

    public function delete(User $user, LessonTemplate $lesson): bool
    {
        return $user->role === 'admin';
    }
}
