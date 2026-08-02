<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

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

    public function permanentlyDelete(User $target, User $admin, Request $request): void
    {
        DB::transaction(function () use ($target, $admin, $request) {
            $target = User::query()->whereKey($target->id)->lockForUpdate()->firstOrFail();

            if (! in_array($target->role, ['teacher', 'student'], true)) {
                throw new ApiException('Hanya akun Guru atau Siswa yang dapat dihapus permanen.', 'USER_PERMANENT_DELETE_FORBIDDEN', 409);
            }

            $references = DB::select(<<<'SQL'
                select tc.table_name, kcu.column_name, rc.delete_rule
                from information_schema.table_constraints tc
                join information_schema.key_column_usage kcu
                  on tc.constraint_name = kcu.constraint_name
                 and tc.constraint_schema = kcu.constraint_schema
                join information_schema.referential_constraints rc
                  on tc.constraint_name = rc.constraint_name
                 and tc.constraint_schema = rc.constraint_schema
                join information_schema.constraint_column_usage ccu
                  on rc.unique_constraint_name = ccu.constraint_name
                 and rc.unique_constraint_schema = ccu.constraint_schema
                where tc.constraint_type = 'FOREIGN KEY'
                  and ccu.table_name = 'users'
                  and ccu.column_name = 'id'
                  and tc.table_schema = current_schema()
                SQL);

            foreach ($references as $reference) {
                if ($reference->table_name === 'users' || $reference->delete_rule !== 'RESTRICT') {
                    continue;
                }

                $query = DB::table($reference->table_name)->where($reference->column_name, $target->id);
                if (in_array($reference->column_name, ['teacher_id', 'student_id', 'user_id'], true)) {
                    $query->delete();
                } else {
                    $query->update([$reference->column_name => $admin->id]);
                }
            }

            $this->auditLogService->record('user.permanently_deleted', $target, $admin, $target->only(['id', 'full_name', 'email', 'role']), ['deleted_by' => $admin->id], [], $request);
            $target->tokens()->delete();
            $target->delete();
        });
    }

    public function forcePasswordReset(User $target, string $newPassword, User $admin, Request $request): User
    {
        return DB::transaction(function () use ($target, $newPassword, $admin, $request) {
            $target = User::query()->whereKey($target->id)->lockForUpdate()->firstOrFail();

            $target->forceFill([
                'password' => Hash::make($newPassword),
                'password_must_change' => true,
            ])->save();
            $target->tokens()->delete();

            $this->auditLogService->record('user.password_force_reset', $target, $admin, [], ['reset_by' => $admin->id], [], $request);

            return $target;
        });
    }
}
