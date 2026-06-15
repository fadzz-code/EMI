<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class UserManagementService
{
    public function __construct(private readonly AuditLogService $auditLogService) {}

    public function update(User $target, array $data, User $admin, Request $request): User
    {
        return DB::transaction(function () use ($target, $data, $admin, $request) {
            $target = User::query()->whereKey($target->id)->lockForUpdate()->firstOrFail();
            $oldValues = $target->only(['full_name', 'email', 'phone']);

            $target->fill([
                'full_name' => $data['full_name'],
                'email' => $data['email'],
                'phone' => $data['phone'] ?? null,
            ])->save();

            $this->auditLogService->record('user.updated', $target, $admin, $oldValues, $target->only(['full_name', 'email', 'phone']), [], $request);

            return $target;
        });
    }

    public function updateStatus(User $target, string $status, ?string $reason, User $admin, Request $request): User
    {
        return DB::transaction(function () use ($target, $status, $reason, $admin, $request) {
            $target = User::query()->whereKey($target->id)->lockForUpdate()->firstOrFail();

            if ($target->id === $admin->id && $status === 'inactive') {
                throw new ApiException('Admin tidak dapat menonaktifkan akun sendiri.', 'CANNOT_DEACTIVATE_SELF', 409);
            }

            if (! in_array($target->status, ['approved', 'inactive'], true)) {
                throw new ApiException('Status pending atau rejected harus diproses melalui alur approval.', 'INVALID_STATUS_TRANSITION', 409);
            }

            if ($target->status === $status) {
                return $target;
            }

            if ($target->role === 'admin' && $target->status === 'approved' && $status === 'inactive') {
                $approvedAdminCount = User::query()
                    ->where('role', 'admin')
                    ->where('status', 'approved')
                    ->whereKeyNot($target->id)
                    ->count();

                if ($approvedAdminCount < 1) {
                    throw new ApiException('Sistem harus memiliki minimal satu Admin approved.', 'LAST_ACTIVE_ADMIN', 409);
                }
            }

            $oldValues = $target->only(['status']);
            $now = now();

            if ($status === 'inactive') {
                $target->teacherClassAssignments()->where('is_active', true)->update(['is_active' => false, 'ended_at' => $now]);
                $target->studentClassMemberships()->where('is_active', true)->update(['is_active' => false, 'ended_at' => $now]);
                $target->tokens()->delete();
            }

            $target->forceFill(['status' => $status])->save();

            $this->auditLogService->record(
                $status === 'inactive' ? 'user.deactivated' : 'user.reactivated',
                $target,
                $admin,
                $oldValues,
                ['status' => $status, 'reason' => $reason],
                [],
                $request,
            );

            return $target;
        });
    }
}
