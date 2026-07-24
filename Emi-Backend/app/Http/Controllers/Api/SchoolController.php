<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\School\ListSchoolsRequest;
use App\Http\Requests\School\StoreSchoolRequest;
use App\Http\Requests\School\UpdateSchoolRequest;
use App\Http\Resources\SchoolResource;
use App\Models\School;
use App\Services\SchoolService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class SchoolController extends Controller
{
    public function __construct(private readonly SchoolService $schoolService) {}

    public function index(ListSchoolsRequest $request): JsonResponse
    {
        Gate::authorize('viewAny', School::class);

        $user = $request->user()->loadMissing([
            'activeTeacherClassAssignment.schoolClass',
            'activeStudentClassMembership.schoolClass',
        ]);
        $validated = $request->validated();
        $perPage = (int) ($validated['per_page'] ?? 15);
        $sortBy = $validated['sort_by'] ?? 'name';
        $sortDirection = $validated['sort_direction'] ?? 'asc';

        $schools = School::query()
            ->withCount('classes')
            ->when($user->role !== 'admin', fn ($query) => $query->whereKey($user->activeSchoolId()))
            ->when($user->role === 'admin' && isset($validated['status']), fn ($query) => $query->where('status', $validated['status']))
            ->when($validated['search'] ?? null, fn ($query, $search) => $query->where('name', 'ilike', "%{$search}%"))
            ->orderBy($sortBy, $sortDirection)
            ->paginate($perPage);

        return ApiResponse::paginated('Data sekolah berhasil diambil.', $schools, SchoolResource::collection($schools->getCollection())->resolve());
    }

    public function store(StoreSchoolRequest $request): JsonResponse
    {
        Gate::authorize('create', School::class);

        $school = $this->schoolService->create($request->validated(), $request->user(), $request);

        return ApiResponse::success('Sekolah berhasil dibuat.', new SchoolResource($school), 201);
    }

    public function show(string $id): JsonResponse
    {
        $school = School::query()
            ->withCount('classes')
            ->findOrFail($id);

        Gate::authorize('view', $school);

        return ApiResponse::success('Detail sekolah berhasil diambil.', new SchoolResource($school));
    }

    public function update(UpdateSchoolRequest $request, string $id): JsonResponse
    {
        $school = School::query()->findOrFail($id);
        Gate::authorize('update', $school);

        $school = $this->schoolService->update($school, $request->validated(), $request->user(), $request);

        return ApiResponse::success('Sekolah berhasil diperbarui.', new SchoolResource($school));
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $school = School::query()->findOrFail($id);
        Gate::authorize('delete', $school);

        $school = $this->schoolService->deactivate($school, $request->user(), $request);

        return ApiResponse::success('Sekolah berhasil dinonaktifkan.', new SchoolResource($school));
    }

    public function forceDestroy(Request $request, string $id): JsonResponse
    {
        $school = School::query()->findOrFail($id);
        Gate::authorize('forceDelete', $school);

        $this->schoolService->forceDelete($school, $request->user(), $request);

        return ApiResponse::success('Sekolah berhasil dihapus permanen.');
    }
}
