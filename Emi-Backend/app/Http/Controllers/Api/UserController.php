<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\UserManagement\ListUsersRequest;
use App\Http\Requests\UserManagement\UpdateUserRequest;
use App\Http\Requests\UserManagement\UpdateUserStatusRequest;
use App\Http\Resources\UserManagementResource;
use App\Models\User;
use App\Services\UserManagementService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;

class UserController extends Controller
{
    public function __construct(private readonly UserManagementService $userManagementService) {}

    public function index(ListUsersRequest $request): JsonResponse
    {
        Gate::authorize('viewAny', User::class);

        $actor = $request->user()->loadMissing('activeTeacherClassAssignment');
        $validated = $request->validated();
        $perPage = (int) ($validated['per_page'] ?? 15);
        $sortBy = $validated['sort_by'] ?? 'full_name';
        $sortDirection = $validated['sort_direction'] ?? 'asc';

        $users = User::query()
            ->with([
                'activeTeacherClassAssignment.schoolClass.school',
                'activeStudentClassMembership.schoolClass.school',
            ])
            ->when($actor->role === 'teacher', function ($query) use ($actor) {
                $query->where('role', 'student')
                    ->whereHas('activeStudentClassMembership', fn ($membershipQuery) => $membershipQuery->where('class_id', $actor->activeClassId()));
            })
            ->when($actor->role === 'admin' && isset($validated['role']), fn ($query) => $query->where('role', $validated['role']))
            ->when($validated['status'] ?? null, fn ($query, $status) => $query->where('status', $status))
            ->when($actor->role === 'admin' && isset($validated['class_id']), function ($query) use ($validated) {
                $query->where(function ($innerQuery) use ($validated) {
                    $innerQuery->whereHas('activeTeacherClassAssignment', fn ($assignmentQuery) => $assignmentQuery->where('class_id', $validated['class_id']))
                        ->orWhereHas('activeStudentClassMembership', fn ($membershipQuery) => $membershipQuery->where('class_id', $validated['class_id']));
                });
            })
            ->when($actor->role === 'admin' && isset($validated['school_id']), function ($query) use ($validated) {
                $query->where(function ($innerQuery) use ($validated) {
                    $innerQuery->whereHas('activeTeacherClassAssignment.schoolClass', fn ($classQuery) => $classQuery->where('school_id', $validated['school_id']))
                        ->orWhereHas('activeStudentClassMembership.schoolClass', fn ($classQuery) => $classQuery->where('school_id', $validated['school_id']));
                });
            })
            ->when($validated['search'] ?? null, function ($query, $search) {
                $query->where(function ($innerQuery) use ($search) {
                    $innerQuery->where('full_name', 'ilike', "%{$search}%")
                        ->orWhere('email', 'ilike', "%{$search}%");
                });
            })
            ->orderBy($sortBy, $sortDirection)
            ->paginate($perPage);

        return ApiResponse::paginated('Data pengguna berhasil diambil.', $users, UserManagementResource::collection($users->getCollection())->resolve());
    }

    public function show(string $id): JsonResponse
    {
        $target = User::query()
            ->with([
                'activeTeacherClassAssignment.schoolClass.school',
                'activeStudentClassMembership.schoolClass.school',
            ])
            ->findOrFail($id);

        Gate::authorize('view', $target);

        return ApiResponse::success('Detail pengguna berhasil diambil.', new UserManagementResource($target));
    }

    public function update(UpdateUserRequest $request, string $id): JsonResponse
    {
        $target = User::query()->findOrFail($id);
        Gate::authorize('update', $target);

        $target = $this->userManagementService->update($target, $request->validated(), $request->user(), $request);

        return ApiResponse::success('Pengguna berhasil diperbarui.', new UserManagementResource($target));
    }

    public function updateStatus(UpdateUserStatusRequest $request, string $id): JsonResponse
    {
        $target = User::query()->findOrFail($id);
        Gate::authorize('updateStatus', $target);

        $target = $this->userManagementService->updateStatus(
            $target,
            $request->validated('status'),
            $request->validated('reason'),
            $request->user(),
            $request,
        );

        return ApiResponse::success('Status pengguna berhasil diperbarui.', new UserManagementResource($target));
    }
}
