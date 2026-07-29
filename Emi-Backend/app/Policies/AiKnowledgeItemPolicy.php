<?php

namespace App\Policies;

use App\Models\AiKnowledgeItem;
use App\Models\User;

class AiKnowledgeItemPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->role === 'admin';
    }

    public function view(User $user, AiKnowledgeItem $item): bool
    {
        return $user->role === 'admin';
    }

    public function create(User $user): bool
    {
        return $user->role === 'admin';
    }

    public function update(User $user, AiKnowledgeItem $item): bool
    {
        return $user->role === 'admin';
    }

    public function delete(User $user, AiKnowledgeItem $item): bool
    {
        return $user->role === 'admin';
    }
}
