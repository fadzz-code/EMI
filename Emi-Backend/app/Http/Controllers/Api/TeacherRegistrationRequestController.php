<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Teacher\ApproveRegistrationRequest;
use App\Http\Requests\Teacher\ListRegistrationRequestsRequest;
use App\Models\RegistrationRequest;
use App\Services\RegistrationApprovalService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;

class TeacherRegistrationRequestController extends Controller
{
    public function __construct(private readonly RegistrationApprovalService $approvalService) {}

    public function index(ListRegistrationRequestsRequest $request): JsonResponse
    {
        Gate::authorize('viewTeacherScope', RegistrationRequest::class);

        $query = RegistrationRequest::with(['user', 'school', 'schoolClass', 'reviewedBy'])
            ->where('requested_role', 'student')
            ->whereHas('schoolClass.teacherAssignments', function ($q) use ($request) {
                $q->where('teacher_id', $request->user()->id)
                    ->where('is_active', true);
            });

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('search')) {
            $query->whereHas('user', function ($q) use ($request) {
                $q->where('name', 'ilike', '%'.$request->search.'%')
                    ->orWhere('email', 'ilike', '%'.$request->search.'%');
            });
        }

        $sortBy = $request->input('sort_by', 'created_at');
        $sortOrder = $request->input('sort_order', 'desc');
        $query->orderBy($sortBy, $sortOrder);

        $perPage = $request->input('per_page', 15);
        $requests = $query->paginate($perPage);

        return ApiResponse::paginated('Data permintaan pendaftaran berhasil diambil.', $requests, $requests->items());
    }

    public function show(string $id): JsonResponse
    {
        $registrationRequest = RegistrationRequest::with(['user', 'school', 'schoolClass', 'reviewedBy'])
            ->findOrFail($id);

        Gate::authorize('viewTeacherScope', $registrationRequest);

        return ApiResponse::success('Detail permintaan pendaftaran berhasil diambil.', $registrationRequest);
    }

    public function approve(ApproveRegistrationRequest $request, string $id): JsonResponse
    {
        $registrationRequest = RegistrationRequest::findOrFail($id);

        Gate::authorize('approveTeacherScope', $registrationRequest);

        $this->approvalService->approve($registrationRequest, $request->user(), $request->validated('review_note'), $request);

        return ApiResponse::success('Permintaan pendaftaran berhasil disetujui.', $registrationRequest->fresh(['reviewedBy']));
    }
}
