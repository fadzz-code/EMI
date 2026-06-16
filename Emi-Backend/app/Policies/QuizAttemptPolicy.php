<?php

namespace App\Policies;

use App\Models\QuizAttempt;
use App\Models\User;
use App\Services\QuizAccessService;

class QuizAttemptPolicy
{
    public function view(User $user, QuizAttempt $attempt): bool
    {
        $attempt->loadMissing('classQuiz');

        return ($user->role === 'student' && $attempt->student_id === $user->id)
            || app(QuizAccessService::class)->canManageQuiz($user, $attempt->classQuiz);
    }

    public function update(User $user, QuizAttempt $attempt): bool
    {
        return $user->role === 'student' && $attempt->student_id === $user->id;
    }
}
