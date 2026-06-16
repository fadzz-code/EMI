<?php

namespace App\Policies;

use App\Models\ClassQuiz;
use App\Models\SchoolClass;
use App\Models\User;
use App\Services\QuizAccessService;

class ClassQuizPolicy
{
    public function viewAny(User $user): bool
    {
        return in_array($user->role, ['admin', 'teacher', 'student'], true);
    }

    public function createForClass(User $user, SchoolClass $class): bool
    {
        return app(QuizAccessService::class)->canManageClass($user, $class);
    }

    public function view(User $user, ClassQuiz $quiz): bool
    {
        return app(QuizAccessService::class)->canManageQuiz($user, $quiz)
            || app(QuizAccessService::class)->studentCanAccessQuiz($user, $quiz);
    }

    public function update(User $user, ClassQuiz $quiz): bool
    {
        return app(QuizAccessService::class)->canManageQuiz($user, $quiz);
    }

    public function delete(User $user, ClassQuiz $quiz): bool
    {
        return app(QuizAccessService::class)->canManageQuiz($user, $quiz);
    }

    public function report(User $user, ClassQuiz $quiz): bool
    {
        return app(QuizAccessService::class)->canManageQuiz($user, $quiz);
    }
}
