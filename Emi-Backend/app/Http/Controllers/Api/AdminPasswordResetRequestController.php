<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\PasswordReset\ApprovePasswordResetRequest;
use App\Http\Requests\PasswordReset\ListPasswordResetRequestsRequest;
use App\Http\Requests\PasswordReset\RejectPasswordResetRequest;
use App\Http\Resources\PasswordResetRequestResource;
use App\Models\PasswordResetRequest;
use App\Services\PasswordResetApprovalService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;

class AdminPasswordResetRequestController extends Controller
{
    public function __construct(private readonly PasswordResetApprovalService $approvalService) {}

    public function index(ListPasswordResetRequestsRequest $request): JsonResponse
    {
        Gate::authorize('viewAny', PasswordResetRequest::class);

        $validated = $request->validated();
        $perPage = min((int) ($validated['per_page'] ?? 15), 100);
        $sortBy = $validated['sort_by'] ?? 'created_at';
        $sortDirection = $validated['sort_direction'] ?? 'desc';

        $requests = PasswordResetRequest::query()
            ->with(['user', 'requestedBy', 'reviewedBy'])
            ->when($validated['status'] ?? null, fn ($query, $status) => $query->where('status', $status))
            ->when($validated['search'] ?? null, function ($query, $search) {
                $query->whereHas('user', function ($userQuery) use ($search) {
                    $userQuery
                        ->where('full_name', 'ilike', "%{$search}%")
                        ->orWhere('email', 'ilike', "%{$search}%");
                });
            })
            ->orderBy($sortBy, $sortDirection)
            ->paginate($perPage);

        return ApiResponse::paginated(
            'Data permintaan reset password berhasil diambil.',
            $requests,
            PasswordResetRequestResource::collection($requests->getCollection())->resolve()
        );
    }

    public function show(string $id): JsonResponse
    {
        $resetRequest = PasswordResetRequest::query()->findOrFail($id);

        Gate::authorize('view', $resetRequest);

        return ApiResponse::success(
            'Detail permintaan reset password berhasil diambil.',
            new PasswordResetRequestResource($resetRequest->load(['user', 'requestedBy', 'reviewedBy']))
        );
    }

    public function approve(ApprovePasswordResetRequest $request, string $id): JsonResponse
    {
        $resetRequest = PasswordResetRequest::query()->findOrFail($id);

        Gate::authorize('approve', $resetRequest);

        $approved = $this->approvalService->approve(
            $resetRequest,
            $request->user(),
            $request->validated('password'),
            $request->validated('review_note'),
            $request,
        );

        return ApiResponse::success('Permintaan reset password berhasil disetujui.', new PasswordResetRequestResource($approved));
    }

    public function reject(RejectPasswordResetRequest $request, string $id): JsonResponse
    {
        $resetRequest = PasswordResetRequest::query()->findOrFail($id);

        Gate::authorize('reject', $resetRequest);

        $rejected = $this->approvalService->reject(
            $resetRequest,
            $request->user(),
            $request->validated('review_note'),
            $request,
        );

        return ApiResponse::success('Permintaan reset password berhasil ditolak.', new PasswordResetRequestResource($rejected));
    }
}
