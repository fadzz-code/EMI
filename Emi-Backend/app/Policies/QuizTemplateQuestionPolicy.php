<?php

namespace App\Policies;

use App\Models\QuizTemplateQuestion;
use App\Models\User;

class QuizTemplateQuestionPolicy
{
    public function view(User $user, QuizTemplateQuestion $question): bool
    {
        return $user->role === 'admin' || ($user->role === 'teacher' && $question->quizTemplate?->status === 'published');
    }

    public function create(User $user): bool
    {
        return $user->role === 'admin';
    }

    public function update(User $user, QuizTemplateQuestion $question): bool
    {
        return $user->role === 'admin';
    }

    public function delete(User $user, QuizTemplateQuestion $question): bool
    {
        return $user->role === 'admin';
    }
}
