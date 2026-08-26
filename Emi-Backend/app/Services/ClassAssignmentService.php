<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\SchoolClass;
use App\Models\StudentClassMembership;
use App\Models\TeacherClassAssignment;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ClassAssignmentService
{
    public function __construct(
        private readonly AuditLogService $auditLogService,
        private readonly ClassTemplateBackfillService $templateBackfillService,
    ) {}

    public function assignTeacher(SchoolClass $schoolClass, string $teacherId, User $admin, Request $request): TeacherClassAssignment
    {
        try {
            return DB::transaction(function () use ($schoolClass, $teacherId, $admin, $request) {
                $class = SchoolClass::query()->with('school')->whereKey($schoolClass->id)->lockForUpdate()->firstOrFail();
                $teacher = User::query()->whereKey($teacherId)->lockForUpdate()->firstOrFail();

                $this->ensureAssignableClass($class);
                $this->ensureUserRoleStatus($teacher, 'teacher');

                $currentClassAssignment = TeacherClassAssignment::query()
                    ->where('class_id', $class->id)
                    ->where('is_active', true)
                    ->lockForUpdate()
                    ->first();
                $currentTeacherAssignment = TeacherClassAssignment::query()
                    ->where('teacher_id', $teacher->id)
                    ->where('is_active', true)
                    ->lockForUpdate()
                    ->first();

                if ($currentClassAssignment?->teacher_id === $teacher->id) {
                    return $currentClassAssignment->load('teacher');
                }

                $oldTeacherId = $currentClassAssignment?->teacher_id;
                $oldClassId = $currentTeacherAssignment?->class_id;

                foreach ([$currentClassAssignment, $currentTeacherAssignment] as $assignment) {
                    if ($assignment && $assignment->is_active) {
                        $assignment->forceFill(['is_active' => false, 'ended_at' => now()])->save();
                    }
                }

                $assignment = TeacherClassAssignment::query()->create([
                    'teacher_id' => $teacher->id,
                    'class_id' => $class->id,
                    'assigned_by' => $admin->id,
                    'is_active' => true,
                    'assigned_at' => now(),
                    'ended_at' => null,
                ]);

                $this->auditLogService->record(
                    $oldTeacherId ? 'class.teacher_reassigned' : 'class.teacher_assigned',
                    $class,
                    $admin,
                    ['old_teacher_id' => $oldTeacherId, 'old_class_id' => $oldClassId],
                    ['teacher_id' => $teacher->id, 'class_id' => $class->id],
                    [],
                    $request,
                );
                $this->templateBackfillService->backfill($class, $teacher, $request);

                return $assignment->load('teacher');
            });
        } catch (QueryException) {
            throw new ApiException('Guru tidak dapat ditetapkan karena konflik assignment aktif.', 'TEACHER_ALREADY_ASSIGNED', 409);
        }
    }

    public function assignStudent(SchoolClass $schoolClass, string $studentId, User $admin, Request $request): StudentClassMembership
    {
        try {
            return DB::transaction(function () use ($schoolClass, $studentId, $admin, $request) {
                $class = SchoolClass::query()->with('school')->whereKey($schoolClass->id)->lockForUpdate()->firstOrFail();
                $student = User::query()->whereKey($studentId)->lockForUpdate()->firstOrFail();

                $this->ensureAssignableClass($class);
                $this->ensureUserRoleStatus($student, 'student');

                $currentMembership = StudentClassMembership::query()
                    ->where('student_id', $student->id)
                    ->where('is_active', true)
                    ->lockForUpdate()
                    ->first();

                if ($currentMembership?->class_id === $class->id) {
                    return $currentMembership->load('student');
                }

                $oldClassId = $currentMembership?->class_id;

                if ($currentMembership) {
                    $currentMembership->forceFill(['is_active' => false, 'ended_at' => now()])->save();
                }

                $membership = StudentClassMembership::query()->create([
                    'student_id' => $student->id,
                    'class_id' => $class->id,
                    'assigned_by' => $admin->id,
                    'is_active' => true,
                    'joined_at' => now(),
                    'ended_at' => null,
                ]);

                $this->auditLogService->record(
                    $oldClassId ? 'class.student_moved' : 'class.student_assigned',
                    $class,
                    $admin,
                    ['student_id' => $student->id, 'old_class_id' => $oldClassId],
                    ['student_id' => $student->id, 'class_id' => $class->id],
                    [],
                    $request,
                );

                return $membership->load('student');
            });
        } catch (QueryException) {
            throw new ApiException('Siswa tidak dapat ditempatkan karena konflik membership aktif.', 'STUDENT_ALREADY_ASSIGNED', 409);
        }
    }

    private function ensureAssignableClass(SchoolClass $class): void
    {
        if ($class->status !== 'active' || $class->school->status !== 'active') {
            throw new ApiException('Kelas dan sekolah harus aktif.', 'CLASS_INACTIVE', 409);
        }
    }

    private function ensureUserRoleStatus(User $user, string $role): void
    {
        if ($user->role !== $role) {
            throw new ApiException('Role pengguna tidak sesuai.', 'INVALID_USER_ROLE', 422);
        }

        if ($user->status !== 'approved') {
            throw new ApiException('Pengguna harus berstatus approved.', 'USER_NOT_APPROVED', 422);
        }
    }
}
