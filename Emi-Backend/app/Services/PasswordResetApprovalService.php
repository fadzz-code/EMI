<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\PasswordResetRequest;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class PasswordResetApprovalService
{
    public function __construct(private readonly AuditLogService $auditLogService) {}

    public function request(User $target, User $requester, Request $request): PasswordResetRequest
    {
        try {
            return DB::transaction(function () use ($target, $requester, $request) {
                $resetRequest = PasswordResetRequest::query()->create([
                    'user_id' => $target->id,
                    'requested_by' => $requester->id,
                    'status' => 'pending',
                ]);

                $this->auditLogService->record(
                    'password_reset.requested',
                    $resetRequest,
                    $requester,
                    null,
                    ['user_id' => $target->id],
                    [],
                    $request,
                );

                return $resetRequest->load(['user', 'requestedBy']);
            });
        } catch (QueryException) {
            throw new ApiException('Sudah ada permintaan reset password yang menunggu persetujuan untuk akun ini.', 'PASSWORD_RESET_ALREADY_PENDING', 409);
        }
    }

    public function approve(PasswordResetRequest $resetRequest, User $approver, string $newPassword, ?string $reviewNote, Request $request): PasswordResetRequest
    {
        return DB::transaction(function () use ($resetRequest, $approver, $newPassword, $reviewNote, $request) {
            $resetRequest = PasswordResetRequest::query()->whereKey($resetRequest->id)->lockForUpdate()->firstOrFail();
            $target = User::query()->whereKey($resetRequest->user_id)->lockForUpdate()->firstOrFail();

            $this->ensurePending($resetRequest);

            $reviewedAt = now();

            $target->forceFill([
                'password' => Hash::make($newPassword),
                'password_must_change' => true,
            ])->save();
            $target->tokens()->delete();

            $resetRequest->forceFill([
                'status' => 'approved',
                'reviewed_by' => $approver->id,
                'review_note' => $reviewNote,
                'reviewed_at' => $reviewedAt,
            ])->save();

            $this->auditLogService->record(
                'password_reset.approved',
                $resetRequest,
                $approver,
                null,
                ['user_id' => $target->id],
                [],
                $request,
            );

            return $resetRequest->load(['user', 'requestedBy', 'reviewedBy']);
        });
    }

    public function reject(PasswordResetRequest $resetRequest, User $approver, string $reviewNote, Request $request): PasswordResetRequest
    {
        return DB::transaction(function () use ($resetRequest, $approver, $reviewNote, $request) {
            $resetRequest = PasswordResetRequest::query()->whereKey($resetRequest->id)->lockForUpdate()->firstOrFail();

            $this->ensurePending($resetRequest);

            $resetRequest->forceFill([
                'status' => 'rejected',
                'reviewed_by' => $approver->id,
                'review_note' => $reviewNote,
                'reviewed_at' => now(),
            ])->save();

            $this->auditLogService->record(
                'password_reset.rejected',
                $resetRequest,
                $approver,
                null,
                ['review_note' => $reviewNote],
                [],
                $request,
            );

            return $resetRequest->load(['user', 'requestedBy', 'reviewedBy']);
        });
    }

    private function ensurePending(PasswordResetRequest $resetRequest): void
    {
        if ($resetRequest->status !== 'pending') {
            throw new ApiException('Permintaan reset password sudah diproses.', 'PASSWORD_RESET_REQUEST_ALREADY_PROCESSED', 409);
        }
    }
}
