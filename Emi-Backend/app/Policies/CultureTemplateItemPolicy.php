<?php

namespace App\Policies;

use App\Models\CultureTemplateItem;
use App\Models\User;

class CultureTemplateItemPolicy
{
    public function view(User $user, CultureTemplateItem $item): bool
    {
        return $user->role === 'admin';
    }

    public function update(User $user, CultureTemplateItem $item): bool
    {
        return $user->role === 'admin';
    }

    public function delete(User $user, CultureTemplateItem $item): bool
    {
        return $user->role === 'admin';
    }
}
