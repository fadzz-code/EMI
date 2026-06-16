<?php

namespace App\Policies;

use App\Models\LessonProgress;
use App\Models\User;

class LessonProgressPolicy
{
    public function update(User $user, LessonProgress $progress): bool
    {
        return $user->role === 'student' && $progress->student_id === $user->id;
    }
}
