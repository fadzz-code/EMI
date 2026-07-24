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

class TeacherPasswordResetRequestController extends Controller
{
    public function __construct(private readonly PasswordResetApprovalService $approvalService) {}

    public function index(ListPasswordResetRequestsRequest $request): JsonResponse
    {
        Gate::authorize('viewTeacherScope', PasswordResetRequest::class);

        $teacherClassId = $request->user()->activeClassId();

        $query = PasswordResetRequest::with(['user', 'requestedBy', 'reviewedBy'])
            ->whereHas('user', function ($userQuery) use ($teacherClassId) {
                $userQuery->where('role', 'student')
                    ->whereHas('activeStudentClassMembership', fn ($membershipQuery) => $membershipQuery->where('class_id', $teacherClassId));
            });

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('search')) {
            $query->whereHas('user', function ($userQuery) use ($request) {
                $userQuery->where('full_name', 'ilike', '%'.$request->search.'%')
                    ->orWhere('email', 'ilike', '%'.$request->search.'%');
            });
        }

        $sortBy = $request->input('sort_by', 'created_at');
        $sortDirection = $request->input('sort_direction', 'desc');
        $query->orderBy($sortBy, $sortDirection);

        $perPage = $request->input('per_page', 15);
        $requests = $query->paginate($perPage);

        return ApiResponse::paginated(
            'Data permintaan reset password berhasil diambil.',
            $requests,
            PasswordResetRequestResource::collection($requests->getCollection())->resolve()
        );
    }

    public function show(string $id): JsonResponse
    {
        $resetRequest = PasswordResetRequest::with(['user', 'requestedBy', 'reviewedBy'])->findOrFail($id);

        Gate::authorize('viewTeacherScope', $resetRequest);

        return ApiResponse::success('Detail permintaan reset password berhasil diambil.', new PasswordResetRequestResource($resetRequest));
    }

    public function approve(ApprovePasswordResetRequest $request, string $id): JsonResponse
    {
        $resetRequest = PasswordResetRequest::findOrFail($id);

        Gate::authorize('approveTeacherScope', $resetRequest);

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
        $resetRequest = PasswordResetRequest::findOrFail($id);

        Gate::authorize('rejectTeacherScope', $resetRequest);

        $rejected = $this->approvalService->reject(
            $resetRequest,
            $request->user(),
            $request->validated('review_note'),
            $request,
        );

        return ApiResponse::success('Permintaan reset password berhasil ditolak.', new PasswordResetRequestResource($rejected));
    }
}
