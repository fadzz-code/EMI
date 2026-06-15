<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\RegistrationRequest;
use App\Models\School;
use App\Models\SchoolClass;
use App\Models\StudentClassMembership;
use App\Models\TeacherClassAssignment;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;

class RegistrationApprovalService
{
    public function approve(RegistrationRequest $registrationRequest, User $admin, ?string $reviewNote = null): RegistrationRequest
    {
        try {
            return DB::transaction(function () use ($registrationRequest, $admin, $reviewNote) {
                $request = RegistrationRequest::query()
                    ->whereKey($registrationRequest->id)
                    ->lockForUpdate()
                    ->firstOrFail();

                $user = User::query()->whereKey($request->user_id)->lockForUpdate()->firstOrFail();
                $school = School::query()->whereKey($request->school_id)->lockForUpdate()->firstOrFail();
                $schoolClass = SchoolClass::query()->whereKey($request->class_id)->lockForUpdate()->firstOrFail();

                $this->ensurePending($request, $user);
                $this->ensureRequestIntegrity($request, $user, $school, $schoolClass);

                if ($request->requested_role === 'teacher') {
                    $this->approveTeacher($request, $user, $admin);
                } else {
                    $this->approveStudent($request, $user, $admin);
                }

                $reviewedAt = now();

                $user->forceFill([
                    'status' => 'approved',
                    'approved_by' => $admin->id,
                    'approved_at' => $reviewedAt,
                    'rejected_reason' => null,
                ])->save();

                $request->forceFill([
                    'status' => 'approved',
                    'reviewed_by' => $admin->id,
                    'review_note' => $reviewNote,
                    'reviewed_at' => $reviewedAt,
                ])->save();

                return $request->load(['user', 'school', 'schoolClass', 'reviewedBy']);
            });
        } catch (QueryException $exception) {
            throw new ApiException('Permintaan tidak dapat disetujui karena konflik data aktif.', 'REGISTRATION_CONFLICT', 409);
        }
    }

    public function reject(RegistrationRequest $registrationRequest, User $admin, string $reviewNote): RegistrationRequest
    {
        return DB::transaction(function () use ($registrationRequest, $admin, $reviewNote) {
            $request = RegistrationRequest::query()
                ->whereKey($registrationRequest->id)
                ->lockForUpdate()
                ->firstOrFail();

            $user = User::query()->whereKey($request->user_id)->lockForUpdate()->firstOrFail();

            $this->ensurePending($request, $user);

            $reviewedAt = now();

            $user->forceFill([
                'status' => 'rejected',
                'rejected_reason' => $reviewNote,
            ])->save();

            $request->forceFill([
                'status' => 'rejected',
                'reviewed_by' => $admin->id,
                'review_note' => $reviewNote,
                'reviewed_at' => $reviewedAt,
            ])->save();

            return $request->load(['user', 'school', 'schoolClass', 'reviewedBy']);
        });
    }

    private function ensurePending(RegistrationRequest $request, User $user): void
    {
        if ($request->status !== 'pending' || $user->status !== 'pending') {
            throw new ApiException('Permintaan pendaftaran sudah diproses.', 'REGISTRATION_ALREADY_PROCESSED', 409);
        }
    }

    private function ensureRequestIntegrity(
        RegistrationRequest $request,
        User $user,
        School $school,
        SchoolClass $schoolClass,
    ): void {
        if ($user->role !== $request->requested_role) {
            throw new ApiException('Role akun tidak sesuai dengan permintaan pendaftaran.', 'REGISTRATION_ROLE_MISMATCH', 409);
        }

        if ($school->status !== 'active' || $schoolClass->status !== 'active') {
            throw new ApiException('Sekolah atau kelas sudah tidak aktif.', 'REGISTRATION_TARGET_INACTIVE', 409);
        }

        if ($schoolClass->school_id !== $school->id) {
            throw new ApiException('Kelas tidak sesuai dengan sekolah yang dipilih.', 'REGISTRATION_CLASS_MISMATCH', 409);
        }
    }

    private function approveTeacher(RegistrationRequest $request, User $teacher, User $admin): void
    {
        if (TeacherClassAssignment::query()->where('teacher_id', $teacher->id)->where('is_active', true)->exists()) {
            throw new ApiException('Guru sudah memiliki kelas aktif.', 'TEACHER_ALREADY_ASSIGNED', 409);
        }

        if (TeacherClassAssignment::query()->where('class_id', $request->class_id)->where('is_active', true)->exists()) {
            throw new ApiException('Kelas sudah memiliki guru aktif.', 'CLASS_ALREADY_HAS_TEACHER', 409);
        }

        TeacherClassAssignment::query()->create([
            'teacher_id' => $teacher->id,
            'class_id' => $request->class_id,
            'assigned_by' => $admin->id,
            'is_active' => true,
            'assigned_at' => now(),
        ]);
    }

    private function approveStudent(RegistrationRequest $request, User $student, User $admin): void
    {
        if (StudentClassMembership::query()->where('student_id', $student->id)->where('is_active', true)->exists()) {
            throw new ApiException('Siswa sudah memiliki kelas aktif.', 'STUDENT_ALREADY_ASSIGNED', 409);
        }

        StudentClassMembership::query()->create([
            'student_id' => $student->id,
            'class_id' => $request->class_id,
            'assigned_by' => $admin->id,
            'is_active' => true,
            'joined_at' => now(),
        ]);
    }
}
