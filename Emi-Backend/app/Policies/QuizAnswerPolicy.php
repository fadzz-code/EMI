<?php

namespace App\Policies;

use App\Models\QuizAnswer;
use App\Models\User;
use App\Services\QuizAccessService;

class QuizAnswerPolicy
{
    public function view(User $user, QuizAnswer $answer): bool
    {
        $answer->loadMissing('attempt.classQuiz');

        return ($user->role === 'student' && $answer->attempt->student_id === $user->id)
            || app(QuizAccessService::class)->canManageQuiz($user, $answer->attempt->classQuiz);
    }
}
