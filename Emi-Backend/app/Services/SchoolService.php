<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\School;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SchoolService
{
    public function __construct(private readonly AuditLogService $auditLogService) {}

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

            if (($data['status'] ?? $school->status) === 'inactive') {
                $this->ensureNoActiveClasses($school);
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

            $this->ensureNoActiveClasses($school);

            $oldValues = $school->only(['status']);
            $school->forceFill(['status' => 'inactive'])->save();

            $this->auditLogService->record('school.deactivated', $school, $admin, $oldValues, $school->only(['status']), [], $request);

            return $school;
        });
    }

    private function ensureNoActiveClasses(School $school): void
    {
        if ($school->classes()->where('status', 'active')->exists()) {
            throw new ApiException('Sekolah masih memiliki kelas aktif. Nonaktifkan atau selesaikan kelas aktif terlebih dahulu.', 'SCHOOL_HAS_ACTIVE_CLASSES', 409);
        }
    }
}
