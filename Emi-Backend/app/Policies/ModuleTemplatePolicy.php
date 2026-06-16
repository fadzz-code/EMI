<?php

namespace App\Policies;

use App\Models\ModuleTemplate;
use App\Models\User;

class ModuleTemplatePolicy
{
    public function viewAny(User $user): bool
    {
        return in_array($user->role, ['admin', 'teacher'], true);
    }

    public function view(User $user, ModuleTemplate $template): bool
    {
        return $user->role === 'admin' || ($user->role === 'teacher' && $template->status === 'published');
    }

    public function create(User $user): bool
    {
        return $user->role === 'admin';
    }

    public function update(User $user, ModuleTemplate $template): bool
    {
        return $user->role === 'admin';
    }

    public function delete(User $user, ModuleTemplate $template): bool
    {
        return $user->role === 'admin';
    }

    public function apply(User $user, ModuleTemplate $template): bool
    {
        return $user->role === 'admin';
    }
}
