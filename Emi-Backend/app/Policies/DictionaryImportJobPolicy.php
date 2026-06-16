<?php

namespace App\Policies;

use App\Models\DictionaryImportJob;
use App\Models\User;

class DictionaryImportJobPolicy
{
    public function viewAny(User $user): bool
    {
        return $user->role === 'admin';
    }

    public function view(User $user, DictionaryImportJob $job): bool
    {
        return $user->role === 'admin';
    }

    public function create(User $user): bool
    {
        return $user->role === 'admin';
    }

    public function confirm(User $user, DictionaryImportJob $job): bool
    {
        return $user->role === 'admin';
    }
}
