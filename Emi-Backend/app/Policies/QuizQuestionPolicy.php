<?php

namespace App\Policies;

use App\Models\QuizQuestion;
use App\Models\User;
use App\Services\QuizAccessService;

class QuizQuestionPolicy
{
    public function view(User $user, QuizQuestion $question): bool
    {
        $question->loadMissing('classQuiz');

        return app(QuizAccessService::class)->canManageQuiz($user, $question->classQuiz)
            || app(QuizAccessService::class)->studentCanAccessQuiz($user, $question->classQuiz);
    }

    public function update(User $user, QuizQuestion $question): bool
    {
        $question->loadMissing('classQuiz');

        return app(QuizAccessService::class)->canManageQuiz($user, $question->classQuiz);
    }

    public function delete(User $user, QuizQuestion $question): bool
    {
        return $this->update($user, $question);
    }
}
