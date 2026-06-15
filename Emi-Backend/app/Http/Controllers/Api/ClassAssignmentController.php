<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\SchoolClass\AssignStudentRequest;
use App\Http\Requests\SchoolClass\AssignTeacherRequest;
use App\Http\Resources\StudentMembershipResource;
use App\Http\Resources\TeacherAssignmentResource;
use App\Models\SchoolClass;
use App\Services\ClassAssignmentService;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;

class ClassAssignmentController extends Controller
{
    public function __construct(private readonly ClassAssignmentService $classAssignmentService) {}

    public function assignTeacher(AssignTeacherRequest $request, string $id): JsonResponse
    {
        $schoolClass = SchoolClass::query()->findOrFail($id);
        Gate::authorize('assignTeacher', $schoolClass);

        $assignment = $this->classAssignmentService->assignTeacher($schoolClass, $request->validated('teacher_id'), $request->user(), $request);

        return ApiResponse::success('Guru kelas berhasil ditetapkan.', new TeacherAssignmentResource($assignment));
    }

    public function assignStudent(AssignStudentRequest $request, string $id): JsonResponse
    {
        $schoolClass = SchoolClass::query()->findOrFail($id);
        Gate::authorize('assignStudent', $schoolClass);

        $membership = $this->classAssignmentService->assignStudent($schoolClass, $request->validated('student_id'), $request->user(), $request);

        return ApiResponse::success('Siswa berhasil ditempatkan ke kelas.', new StudentMembershipResource($membership));
    }
}
