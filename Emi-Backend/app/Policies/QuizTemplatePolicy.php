<?php

namespace App\Policies;

use App\Models\QuizTemplate;
use App\Models\User;

class QuizTemplatePolicy
{
    public function viewAny(User $user): bool
    {
        return in_array($user->role, ['admin', 'teacher'], true);
    }

    public function view(User $user, QuizTemplate $template): bool
    {
        return $user->role === 'admin' || ($user->role === 'teacher' && $template->status === 'published');
    }

    public function create(User $user): bool
    {
        return $user->role === 'admin';
    }

    public function update(User $user, QuizTemplate $template): bool
    {
        return $user->role === 'admin';
    }

    public function delete(User $user, QuizTemplate $template): bool
    {
        return $user->role === 'admin';
    }

    public function apply(User $user, QuizTemplate $template): bool
    {
        return $user->role === 'admin';
    }
}
