<?php

namespace App\Policies;

use App\Models\CultureTemplate;
use App\Models\User;

class CultureTemplatePolicy
{
    public function viewAny(User $user): bool
    {
        return $user->role === 'admin';
    }

    public function view(User $user, CultureTemplate $template): bool
    {
        return $user->role === 'admin';
    }

    public function create(User $user): bool
    {
        return $user->role === 'admin';
    }

    public function update(User $user, CultureTemplate $template): bool
    {
        return $user->role === 'admin';
    }

    public function delete(User $user, CultureTemplate $template): bool
    {
        return $user->role === 'admin';
    }

    public function apply(User $user, CultureTemplate $template): bool
    {
        return $user->role === 'admin';
    }
}
