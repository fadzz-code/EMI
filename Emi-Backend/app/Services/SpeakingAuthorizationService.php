<?php

namespace App\Services;

use App\Models\SpeakingAttempt;
use App\Models\User;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\DB;

class SpeakingAuthorizationService
{
    public function teacherAttemptQuery(User $teacher): Builder
    {
        if ($teacher->role !== 'teacher' || $teacher->status !== 'approved') {
            return SpeakingAttempt::query()->whereRaw('1 = 0');
        }

        $classIds = $teacher->teacherClassAssignments()
            ->where('is_active', true)
            ->whereHas('schoolClass', fn ($query) => $query
                ->where('status', 'active')
                ->whereHas('school', fn ($school) => $school->where('status', 'active')))
            ->select('class_id');

        return SpeakingAttempt::query()
            ->whereNotNull('submitted_at')
            ->whereHas('student', fn ($query) => $query
                ->where('role', 'student')
                ->where('status', 'approved'))
            ->whereHas('exercise', fn ($query) => $query
                ->where(fn ($exercise) => $exercise
                    ->where(fn ($global) => $global
                        ->whereNull('classroom_id')
                        ->whereExists(fn ($membership) => $membership
                            ->select(DB::raw(1))
                            ->from('student_class_memberships')
                            ->whereColumn('student_class_memberships.student_id', 'speaking_attempts.student_id')
                            ->where('student_class_memberships.is_active', true)
                            ->whereIn('student_class_memberships.class_id', $classIds)))
                    ->orWhere(fn ($class) => $class
                        ->whereIn('classroom_id', $classIds)
                        ->whereHas('classroom', fn ($schoolClass) => $schoolClass
                            ->where('status', 'active')
                            ->whereHas('school', fn ($school) => $school->where('status', 'active')))
                        ->whereExists(fn ($membership) => $membership
                            ->select(DB::raw(1))
                            ->from('student_class_memberships')
                            ->whereColumn('student_class_memberships.student_id', 'speaking_attempts.student_id')
                            ->whereColumn('student_class_memberships.class_id', 'speaking_exercises.classroom_id')
                            ->where('student_class_memberships.is_active', true)))));
    }

    public function teacherCanAccessAttempt(User $teacher, SpeakingAttempt $attempt): bool
    {
        return $this->teacherAttemptQuery($teacher)->whereKey($attempt->id)->exists();
    }
}
