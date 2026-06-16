<?php

namespace App\Policies;

use App\Models\DictionaryCategory;
use App\Models\User;

class DictionaryCategoryPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->status === 'approved';
    }

    public function view(User $user, DictionaryCategory $category): bool
    {
        return $user->role === 'admin' || ($user->status === 'approved' && $category->status === 'active');
    }

    public function create(User $user): bool
    {
        return $user->role === 'admin';
    }

    public function update(User $user, DictionaryCategory $category): bool
    {
        return $user->role === 'admin';
    }

    public function delete(User $user, DictionaryCategory $category): bool
    {
        return $user->role === 'admin';
    }
}
