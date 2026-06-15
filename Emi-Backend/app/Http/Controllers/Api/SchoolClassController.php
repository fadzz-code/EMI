<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\SchoolClass\ListClassesRequest;
use App\Http\Requests\SchoolClass\ListClassStudentsRequest;
use App\Http\Requests\SchoolClass\StoreSchoolClassRequest;
use App\Http\Requests\SchoolClass\UpdateSchoolClassRequest;
use App\Http\Resources\ClassStudentResource;
use App\Http\Resources\SchoolClassResource;
use App\Models\SchoolClass;
use App\Services\SchoolClassService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class SchoolClassController extends Controller
{
    public function __construct(private readonly SchoolClassService $schoolClassService) {}

    public function index(ListClassesRequest $request): JsonResponse
    {
        Gate::authorize('viewAny', SchoolClass::class);

        $user = $request->user()->loadMissing(['activeTeacherClassAssignment', 'activeStudentClassMembership']);
        $validated = $request->validated();
        $perPage = (int) ($validated['per_page'] ?? 15);
        $sortBy = $validated['sort_by'] ?? 'name';
        $sortDirection = $validated['sort_direction'] ?? 'asc';

        $classes = SchoolClass::query()
            ->with(['school', 'activeTeacherAssignment.teacher'])
            ->withCount(['activeStudentMemberships as active_students_count'])
            ->when($user->role !== 'admin', fn ($query) => $query->whereKey($user->activeClassId()))
            ->when($user->role === 'admin' && isset($validated['school_id']), fn ($query) => $query->where('school_id', $validated['school_id']))
            ->when($user->role === 'admin' && isset($validated['status']), fn ($query) => $query->where('status', $validated['status']))
            ->when($user->role === 'admin' && isset($validated['academic_year']), fn ($query) => $query->where('academic_year', $validated['academic_year']))
            ->when($user->role === 'admin' && array_key_exists('grade_level', $validated), fn ($query) => $query->where('grade_level', $validated['grade_level']))
            ->when($user->role === 'admin' && isset($validated['teacher_id']), function ($query) use ($validated) {
                $query->whereHas('activeTeacherAssignment', fn ($assignmentQuery) => $assignmentQuery->where('teacher_id', $validated['teacher_id']));
            })
            ->when($validated['search'] ?? null, fn ($query, $search) => $query->where('name', 'ilike', "%{$search}%"))
            ->orderBy($sortBy, $sortDirection)
            ->paginate($perPage);

        return ApiResponse::paginated('Data kelas berhasil diambil.', $classes, SchoolClassResource::collection($classes->getCollection())->resolve());
    }

    public function store(StoreSchoolClassRequest $request): JsonResponse
    {
        Gate::authorize('create', SchoolClass::class);

        $schoolClass = $this->schoolClassService->create($request->validated(), $request->user(), $request);

        return ApiResponse::success('Kelas berhasil dibuat.', new SchoolClassResource($schoolClass->load('school')), 201);
    }

    public function show(string $id): JsonResponse
    {
        $schoolClass = SchoolClass::query()
            ->with(['school', 'activeTeacherAssignment.teacher'])
            ->withCount(['activeStudentMemberships as active_students_count'])
            ->findOrFail($id);

        Gate::authorize('view', $schoolClass);

        return ApiResponse::success('Detail kelas berhasil diambil.', new SchoolClassResource($schoolClass));
    }

    public function update(UpdateSchoolClassRequest $request, string $id): JsonResponse
    {
        $schoolClass = SchoolClass::query()->findOrFail($id);
        Gate::authorize('update', $schoolClass);

        $schoolClass = $this->schoolClassService->update($schoolClass, $request->validated(), $request->user(), $request);

        return ApiResponse::success('Kelas berhasil diperbarui.', new SchoolClassResource($schoolClass->load('school')));
    }

    public function destroy(string $id, Request $request): JsonResponse
    {
        $schoolClass = SchoolClass::query()->findOrFail($id);
        Gate::authorize('delete', $schoolClass);

        $schoolClass = $this->schoolClassService->deactivate($schoolClass, $request->user(), $request);

        return ApiResponse::success('Kelas berhasil dinonaktifkan.', new SchoolClassResource($schoolClass));
    }

    public function students(ListClassStudentsRequest $request, string $id): JsonResponse
    {
        $schoolClass = SchoolClass::query()->findOrFail($id);
        Gate::authorize('viewStudents', $schoolClass);

        $validated = $request->validated();
        $perPage = (int) ($validated['per_page'] ?? 15);
        $sortBy = $validated['sort_by'] ?? 'full_name';
        $sortDirection = $validated['sort_direction'] ?? 'asc';

        $memberships = $schoolClass->activeStudentMemberships()
            ->with('student')
            ->whereHas('student', function ($query) use ($validated) {
                $query
                    ->when($validated['status'] ?? null, fn ($userQuery, $status) => $userQuery->where('status', $status))
                    ->when($validated['search'] ?? null, function ($userQuery, $search) {
                        $userQuery->where(function ($innerQuery) use ($search) {
                            $innerQuery->where('full_name', 'ilike', "%{$search}%")
                                ->orWhere('email', 'ilike', "%{$search}%");
                        });
                    });
            })
            ->join('users', 'student_class_memberships.student_id', '=', 'users.id')
            ->select('student_class_memberships.*')
            ->orderBy("users.{$sortBy}", $sortDirection)
            ->paginate($perPage);

        return ApiResponse::paginated('Data siswa kelas berhasil diambil.', $memberships, ClassStudentResource::collection($memberships->getCollection())->resolve());
    }
}
