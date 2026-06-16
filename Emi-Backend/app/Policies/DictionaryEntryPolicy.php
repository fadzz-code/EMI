<?php

namespace App\Policies;

use App\Models\DictionaryEntry;
use App\Models\User;

class DictionaryEntryPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->status === 'approved';
    }

    public function view(User $user, DictionaryEntry $entry): bool
    {
        return $user->role === 'admin'
            || ($user->status === 'approved' && $entry->status === 'active' && $entry->category?->status === 'active');
    }

    public function create(User $user): bool
    {
        return $user->role === 'admin';
    }

    public function update(User $user, DictionaryEntry $entry): bool
    {
        return $user->role === 'admin';
    }

    public function delete(User $user, DictionaryEntry $entry): bool
    {
        return $user->role === 'admin';
    }
}
