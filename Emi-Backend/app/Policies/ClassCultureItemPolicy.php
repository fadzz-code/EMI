<?php

namespace App\Policies;

use App\Models\ClassCultureItem;
use App\Models\SchoolClass;
use App\Models\User;
use App\Services\CultureAccessService;

class ClassCultureItemPolicy
{
    public function viewAny(User $user): bool
    {
        return in_array($user->role, ['admin', 'teacher', 'student'], true);
    }

    public function createForClass(User $user, SchoolClass $class): bool
    {
        return app(CultureAccessService::class)->canManageClass($user, $class);
    }

    public function view(User $user, ClassCultureItem $item): bool
    {
        $accessService = app(CultureAccessService::class);

        if ($user->role === 'student') {
            return $accessService->studentCanAccessItem($user, $item);
        }

        return $accessService->canManageItem($user, $item);
    }

    public function update(User $user, ClassCultureItem $item): bool
    {
        return app(CultureAccessService::class)->canManageItem($user, $item);
    }

    public function delete(User $user, ClassCultureItem $item): bool
    {
        return app(CultureAccessService::class)->canManageItem($user, $item);
    }
}
