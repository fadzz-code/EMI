<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\School;
use App\Models\SchoolClass;
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

                if (($data['status'] ?? $schoolClass->status) === 'inactive') {
                    $this->ensureNoActiveRelations($schoolClass);
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

            $this->ensureNoActiveRelations($schoolClass);

            $oldValues = $schoolClass->only(['status']);
            $schoolClass->forceFill(['status' => 'inactive'])->save();

            $this->auditLogService->record('class.deactivated', $schoolClass, $admin, $oldValues, $schoolClass->only(['status']), [], $request);

            return $schoolClass;
        });
    }

    private function ensureNoActiveRelations(SchoolClass $schoolClass): void
    {
        if ($schoolClass->activeTeacherAssignment()->exists()) {
            throw new ApiException('Kelas masih memiliki guru aktif.', 'CLASS_HAS_ACTIVE_TEACHER', 409);
        }

        if ($schoolClass->activeStudentMemberships()->exists()) {
            throw new ApiException('Kelas masih memiliki siswa aktif.', 'CLASS_HAS_ACTIVE_STUDENTS', 409);
        }
    }
}
