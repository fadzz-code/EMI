<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\ClassModule;
use App\Models\ClassQuiz;
use App\Models\LessonProgress;
use App\Models\ModuleProgress;
use App\Models\QuizAttempt;
use App\Models\RegistrationRequest;
use App\Models\School;
use App\Models\SchoolClass;
use App\Models\SpeakingExercise;
use App\Models\StudentClassMembership;
use App\Models\TeacherClassAssignment;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SchoolClassService
{
    public function __construct(private readonly AuditLogService $auditLogService) {}

    public function create(array $data, User $admin, Request $request): SchoolClass
    {
        try {
            return DB::transaction(function () use ($data, $admin, $request) {
                $school = School::query()->whereKey($data['school_id'])->lockForUpdate()->firstOrFail();

                if (($data['status'] ?? 'active') === 'active' && $school->status !== 'active') {
                    throw new ApiException('Kelas aktif hanya dapat dibuat pada sekolah aktif.', 'SCHOOL_INACTIVE', 409);
                }

                $schoolClass = SchoolClass::query()->create([
                    'school_id' => $school->id,
                    'name' => $data['name'],
                    'grade_level' => $data['grade_level'] ?? null,
                    'academic_year' => $data['academic_year'],
                    'status' => $data['status'] ?? 'active',
                    'created_by' => $admin->id,
                ]);

                $this->auditLogService->record('class.created', $schoolClass, $admin, null, $schoolClass->toArray(), [], $request);

                return $schoolClass;
            });
        } catch (QueryException) {
            throw new ApiException('Kelas dengan nama dan tahun ajaran tersebut sudah ada pada sekolah ini.', 'CLASS_DUPLICATE', 409);
        }
    }

    public function update(SchoolClass $schoolClass, array $data, User $admin, Request $request): SchoolClass
    {
        try {
            return DB::transaction(function () use ($schoolClass, $data, $admin, $request) {
                $schoolClass = SchoolClass::query()->whereKey($schoolClass->id)->lockForUpdate()->firstOrFail();
                $schoolClass->load('school');
                $oldValues = $schoolClass->only(['name', 'grade_level', 'academic_year', 'status']);

                if (($data['status'] ?? $schoolClass->status) === 'active' && $schoolClass->school->status !== 'active') {
                    throw new ApiException('Kelas tidak dapat diaktifkan pada sekolah inactive.', 'SCHOOL_INACTIVE', 409);
                }

                if (($data['status'] ?? $schoolClass->status) === 'inactive' && $schoolClass->status !== 'inactive') {
                    $this->releaseActiveRelations($schoolClass, $admin, $request);
                }

                $schoolClass->fill([
                    'name' => $data['name'],
                    'grade_level' => $data['grade_level'] ?? null,
                    'academic_year' => $data['academic_year'],
                    'status' => $data['status'],
                ])->save();

                $action = $oldValues['status'] === 'inactive' && $schoolClass->status === 'active'
                    ? 'class.reactivated'
                    : 'class.updated';

                $this->auditLogService->record($action, $schoolClass, $admin, $oldValues, $schoolClass->only(['name', 'grade_level', 'academic_year', 'status']), [], $request);

                return $schoolClass;
            });
        } catch (QueryException) {
            throw new ApiException('Kelas dengan nama dan tahun ajaran tersebut sudah ada pada sekolah ini.', 'CLASS_DUPLICATE', 409);
        }
    }

    public function deactivate(SchoolClass $schoolClass, User $admin, Request $request): SchoolClass
    {
        return DB::transaction(function () use ($schoolClass, $admin, $request) {
            $schoolClass = SchoolClass::query()->whereKey($schoolClass->id)->lockForUpdate()->firstOrFail();

            if ($schoolClass->status === 'inactive') {
                return $schoolClass;
            }

            $this->releaseActiveRelations($schoolClass, $admin, $request);

            $oldValues = $schoolClass->only(['status']);
            $schoolClass->forceFill(['status' => 'inactive'])->save();

            $this->auditLogService->record('class.deactivated', $schoolClass, $admin, $oldValues, $schoolClass->only(['status']), [], $request);

            return $schoolClass;
        });
    }

    private function releaseActiveRelations(SchoolClass $schoolClass, User $admin, Request $request): void
    {
        $releasedTeachers = TeacherClassAssignment::query()
            ->where('class_id', $schoolClass->id)
            ->where('is_active', true)
            ->pluck('id');

        if ($releasedTeachers->isNotEmpty()) {
            TeacherClassAssignment::query()
                ->whereIn('id', $releasedTeachers)
                ->update(['is_active' => false, 'ended_at' => now()]);

            $this->auditLogService->record(
                'class.teacher_released',
                $schoolClass,
                $admin,
                null,
                ['assignment_ids' => $releasedTeachers->all()],
                [],
                $request,
            );
        }

        $releasedStudents = StudentClassMembership::query()
            ->where('class_id', $schoolClass->id)
            ->where('is_active', true)
            ->pluck('id');

        if ($releasedStudents->isNotEmpty()) {
            StudentClassMembership::query()
                ->whereIn('id', $releasedStudents)
                ->update(['is_active' => false, 'ended_at' => now()]);

            $this->auditLogService->record(
                'class.students_released',
                $schoolClass,
                $admin,
                null,
                ['membership_ids' => $releasedStudents->all()],
                [],
                $request,
            );
        }
    }

    public function forceDelete(SchoolClass $schoolClass, User $admin, Request $request): void
    {
        DB::transaction(function () use ($schoolClass, $admin, $request) {
            $schoolClass = SchoolClass::query()->whereKey($schoolClass->id)->lockForUpdate()->firstOrFail();
            $oldValues = $schoolClass->only(['id', 'school_id', 'name', 'grade_level', 'academic_year', 'status']);

            $this->purgeSpeakingData($schoolClass->id);
            $this->purgeLearningData($schoolClass->id);

            TeacherClassAssignment::query()->where('class_id', $schoolClass->id)->delete();
            StudentClassMembership::query()->where('class_id', $schoolClass->id)->delete();
            RegistrationRequest::query()->where('class_id', $schoolClass->id)->delete();

            $this->auditLogService->record('class.deleted', $schoolClass, $admin, $oldValues, null, [], $request);

            $schoolClass->delete();
        });
    }

    private function purgeSpeakingData(string $classId): void
    {
        // speaking_attempts.speaking_exercise_id has an onDelete('cascade') DB
        // constraint, so a hard delete of the exercise also removes its attempts.
        SpeakingExercise::withTrashed()
            ->where('classroom_id', $classId)
            ->get()
            ->each(fn (SpeakingExercise $exercise) => $exercise->forceDelete());
    }

    private function purgeLearningData(string $classId): void
    {
        $quizIds = ClassQuiz::withTrashed()->where('class_id', $classId)->pluck('id');

        if ($quizIds->isNotEmpty()) {
            QuizAttempt::query()->whereIn('class_quiz_id', $quizIds)->delete();
            ClassQuiz::withTrashed()->whereIn('id', $quizIds)->forceDelete();
        }

        $moduleIds = ClassModule::withTrashed()->where('class_id', $classId)->pluck('id');

        if ($moduleIds->isNotEmpty()) {
            $lessonIds = DB::table('class_lessons')->whereIn('class_module_id', $moduleIds)->pluck('id');

            if ($lessonIds->isNotEmpty()) {
                LessonProgress::query()->whereIn('class_lesson_id', $lessonIds)->delete();
            }

            ModuleProgress::query()->whereIn('class_module_id', $moduleIds)->delete();
            ClassModule::withTrashed()->whereIn('id', $moduleIds)->forceDelete();
        }
    }
}
