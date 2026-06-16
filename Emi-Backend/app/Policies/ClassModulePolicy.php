<?php

namespace App\Policies;

use App\Models\ClassModule;
use App\Models\SchoolClass;
use App\Models\User;
use App\Services\LearningAccessService;

class ClassModulePolicy
{
    public function viewAny(User $user): bool
    {
        return in_array($user->role, ['admin', 'teacher', 'student'], true);
    }

    public function createForClass(User $user, SchoolClass $class): bool
    {
        return app(LearningAccessService::class)->canManageClass($user, $class);
    }

    public function view(User $user, ClassModule $module): bool
    {
        return app(LearningAccessService::class)->canManageModule($user, $module);
    }

    public function update(User $user, ClassModule $module): bool
    {
        return app(LearningAccessService::class)->canManageModule($user, $module);
    }

    public function delete(User $user, ClassModule $module): bool
    {
        return app(LearningAccessService::class)->canManageModule($user, $module);
    }
}
