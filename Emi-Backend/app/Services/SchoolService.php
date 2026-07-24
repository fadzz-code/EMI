<?php

namespace App\Services;

use App\Models\School;
use App\Models\SchoolClass;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SchoolService
{
    public function __construct(
        private readonly AuditLogService $auditLogService,
        private readonly SchoolClassService $schoolClassService,
    ) {}

    public function create(array $data, User $admin, Request $request): School
    {
        return DB::transaction(function () use ($data, $admin, $request) {
            $school = School::query()->create([
                'name' => $data['name'],
                'address' => $data['address'] ?? null,
                'phone' => $data['phone'] ?? null,
                'status' => $data['status'] ?? 'active',
                'created_by' => $admin->id,
            ]);

            $this->auditLogService->record('school.created', $school, $admin, null, $school->toArray(), [], $request);

            return $school;
        });
    }

    public function update(School $school, array $data, User $admin, Request $request): School
    {
        return DB::transaction(function () use ($school, $data, $admin, $request) {
            $school = School::query()->whereKey($school->id)->lockForUpdate()->firstOrFail();
            $oldValues = $school->only(['name', 'address', 'phone', 'status']);

            if (($data['status'] ?? $school->status) === 'inactive' && $school->status !== 'inactive') {
                $this->deactivateAllClasses($school, $admin, $request);
            }

            $school->fill([
                'name' => $data['name'],
                'address' => $data['address'] ?? null,
                'phone' => $data['phone'] ?? null,
                'status' => $data['status'],
            ])->save();

            $action = $oldValues['status'] === 'inactive' && $school->status === 'active'
                ? 'school.reactivated'
                : 'school.updated';

            $this->auditLogService->record($action, $school, $admin, $oldValues, $school->only(['name', 'address', 'phone', 'status']), [], $request);

            return $school;
        });
    }

    public function deactivate(School $school, User $admin, Request $request): School
    {
        return DB::transaction(function () use ($school, $admin, $request) {
            $school = School::query()->whereKey($school->id)->lockForUpdate()->firstOrFail();

            if ($school->status === 'inactive') {
                return $school;
            }

            $this->deactivateAllClasses($school, $admin, $request);

            $oldValues = $school->only(['status']);
            $school->forceFill(['status' => 'inactive'])->save();

            $this->auditLogService->record('school.deactivated', $school, $admin, $oldValues, $school->only(['status']), [], $request);

            return $school;
        });
    }

    private function deactivateAllClasses(School $school, User $admin, Request $request): void
    {
        $classIds = SchoolClass::query()
            ->where('school_id', $school->id)
            ->where('status', 'active')
            ->pluck('id');

        foreach ($classIds as $classId) {
            $schoolClass = SchoolClass::query()->whereKey($classId)->lockForUpdate()->firstOrFail();
            $this->schoolClassService->deactivate($schoolClass, $admin, $request);
        }
    }

    public function forceDelete(School $school, User $admin, Request $request): void
    {
        DB::transaction(function () use ($school, $admin, $request) {
            $school = School::query()->whereKey($school->id)->lockForUpdate()->firstOrFail();
            $oldValues = $school->only(['id', 'name', 'address', 'phone', 'status']);

            $classIds = SchoolClass::query()->where('school_id', $school->id)->pluck('id');

            foreach ($classIds as $classId) {
                $schoolClass = SchoolClass::query()->whereKey($classId)->lockForUpdate()->firstOrFail();
                $this->schoolClassService->forceDelete($schoolClass, $admin, $request);
            }

            $this->auditLogService->record('school.deleted', $school, $admin, $oldValues, null, [], $request);

            $school->delete();
        });
    }
}
