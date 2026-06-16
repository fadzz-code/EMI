<?php

namespace App\Policies;

use App\Models\ClassLesson;
use App\Models\ClassModule;
use App\Models\User;
use App\Services\LearningAccessService;

class ClassLessonPolicy
{
    public function createForModule(User $user, ClassModule $module): bool
    {
        return app(LearningAccessService::class)->canManageModule($user, $module);
    }

    public function view(User $user, ClassLesson $lesson): bool
    {
        return app(LearningAccessService::class)->canManageLesson($user, $lesson);
    }

    public function update(User $user, ClassLesson $lesson): bool
    {
        return app(LearningAccessService::class)->canManageLesson($user, $lesson);
    }

    public function delete(User $user, ClassLesson $lesson): bool
    {
        return app(LearningAccessService::class)->canManageLesson($user, $lesson);
    }
}
