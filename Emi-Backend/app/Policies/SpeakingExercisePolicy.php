<?php

namespace App\Policies;

use App\Models\SpeakingExercise;
use App\Models\User;

class SpeakingExercisePolicy
{
    public function apply(User $user, SpeakingExercise $exercise): bool
    {
        return $user->role === 'admin' && $exercise->classroom_id === null;
    }

    public function delete(User $user, SpeakingExercise $exercise): bool
    {
        $exercise->loadMissing('classroom.school');

        return $user->role === 'teacher'
            && $exercise->classroom_id !== null
            && $exercise->created_by_id === $user->id
            && $exercise->classroom?->status === 'active'
            && $exercise->classroom->school?->status === 'active'
            && $user->teacherClassAssignments()
                ->where('class_id', $exercise->classroom_id)
                ->where('is_active', true)
                ->exists();
    }
}
