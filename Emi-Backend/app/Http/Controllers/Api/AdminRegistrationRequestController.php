<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\ApproveRegistrationRequest;
use App\Http\Requests\Admin\ListRegistrationRequestsRequest;
use App\Http\Requests\Admin\RejectRegistrationRequest;
use App\Http\Resources\RegistrationRequestResource;
use App\Models\RegistrationRequest;
use App\Services\RegistrationApprovalService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;

class AdminRegistrationRequestController extends Controller
{
    public function __construct(private readonly RegistrationApprovalService $approvalService) {}

    public function index(ListRegistrationRequestsRequest $request): JsonResponse
    {
        Gate::authorize('viewAny', RegistrationRequest::class);

        $validated = $request->validated();
        $perPage = min((int) ($validated['per_page'] ?? 15), 100);
        $sortBy = $validated['sort_by'] ?? 'created_at';
        $sortDirection = $validated['sort_direction'] ?? 'desc';

        $requests = RegistrationRequest::query()
            ->with(['user', 'school', 'schoolClass', 'reviewedBy'])
            ->when($validated['status'] ?? null, fn ($query, $status) => $query->where('status', $status))
            ->when($validated['requested_role'] ?? null, fn ($query, $role) => $query->where('requested_role', $role))
            ->when($validated['school_id'] ?? null, fn ($query, $schoolId) => $query->where('school_id', $schoolId))
            ->when($validated['class_id'] ?? null, fn ($query, $classId) => $query->where('class_id', $classId))
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
            'Data permintaan pendaftaran berhasil diambil.',
            $requests,
            RegistrationRequestResource::collection($requests->getCollection())->resolve()
        );
    }

    public function show(string $id): JsonResponse
    {
        $registrationRequest = RegistrationRequest::query()->findOrFail($id);

        Gate::authorize('view', $registrationRequest);

        return ApiResponse::success(
            'Detail permintaan pendaftaran berhasil diambil.',
            new RegistrationRequestResource($registrationRequest->load(['user', 'school', 'schoolClass', 'reviewedBy']))
        );
    }

    public function approve(ApproveRegistrationRequest $request, string $id): JsonResponse
    {
        $registrationRequest = RegistrationRequest::query()->findOrFail($id);

        Gate::authorize('approve', $registrationRequest);

        $approved = $this->approvalService->approve(
            $registrationRequest,
            $request->user(),
            $request->validated('review_note')
        );

        return ApiResponse::success('Permintaan pendaftaran berhasil disetujui.', new RegistrationRequestResource($approved));
    }

    public function reject(RejectRegistrationRequest $request, string $id): JsonResponse
    {
        $registrationRequest = RegistrationRequest::query()->findOrFail($id);

        Gate::authorize('reject', $registrationRequest);

        $rejected = $this->approvalService->reject(
            $registrationRequest,
            $request->user(),
            $request->validated('review_note')
        );

        return ApiResponse::success('Permintaan pendaftaran berhasil ditolak.', new RegistrationRequestResource($rejected));
    }
}
