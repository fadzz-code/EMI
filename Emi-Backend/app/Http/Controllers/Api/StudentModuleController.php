<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Learning\ListStudentModulesRequest;
use App\Http\Resources\StudentModuleResource;
use App\Models\ClassModule;
use App\Models\ModuleProgress;
use App\Services\LearningAccessService;
use App\Services\LearningProgressService;
use Illuminate\Http\JsonResponse;

class StudentModuleController extends Controller
{
    public function __construct(
        private readonly LearningAccessService $accessService,
        private readonly LearningProgressService $progressService,
    ) {}

    public function index(ListStudentModulesRequest $request): JsonResponse
    {
        $student = $request->user();
        $classId = $this->accessService->studentClassId($student);
        $validated = $request->validated();
        $perPage = (int) ($validated['per_page'] ?? 15);
        $sortBy = $validated['sort_by'] ?? 'sort_order';
        $sortDirection = $validated['sort_direction'] ?? 'asc';

        $modules = ClassModule::query()
            ->withCount(['lessons as lessons_count' => fn ($query) => $query->where('status', 'published')])
            ->where('class_id', $classId)
            ->where('status', 'published')
            ->whereHas('schoolClass', fn ($query) => $query->where('status', 'active')->whereHas('school', fn ($school) => $school->where('status', 'active')))
            ->when($validated['search'] ?? null, fn ($query, $search) => $query->where(fn ($inner) => $inner->where('title', 'ilike', "%{$search}%")->orWhere('description', 'ilike', "%{$search}%")))
            ->when($validated['status'] ?? null, function ($query, $status) use ($student) {
                if ($status === 'not_started') {
                    $query->where(fn ($inner) => $inner
                        ->whereDoesntHave('progress', fn ($progress) => $progress->where('student_id', $student->id))
                        ->orWhereHas('progress', fn ($progress) => $progress->where('student_id', $student->id)->where('status', 'not_started')));

                    return;
                }

                $query->whereHas('progress', fn ($progress) => $progress->where('student_id', $student->id)->where('status', $status));
            })
            ->orderBy($sortBy, $sortDirection)
            ->paginate($perPage);

        $progress = ModuleProgress::query()
            ->where('student_id', $student->id)
            ->whereIn('class_module_id', $modules->getCollection()->pluck('id'))
            ->get()
            ->keyBy('class_module_id');

        $modules->getCollection()->each(function (ClassModule $module) use ($progress) {
            $module->setAttribute('progress_for_student', $progress->get($module->id));
        });

        return ApiResponse::paginated('Data modul siswa berhasil diambil.', $modules, StudentModuleResource::collection($modules->getCollection())->resolve());
    }

    public function show(ListStudentModulesRequest $request, string $id): JsonResponse
    {
        $module = ClassModule::query()
            ->with(['lessons' => fn ($query) => $query->where('status', 'published')->orderBy('sort_order')])
            ->findOrFail($id);

        if (! $this->accessService->studentCanAccessModule($request->user(), $module)) {
            abort(404);
        }

        $module->setAttribute('progress_for_student', ModuleProgress::query()->where('student_id', $request->user()->id)->where('class_module_id', $module->id)->first());

        return ApiResponse::success('Detail modul siswa berhasil diambil.', new StudentModuleResource($module));
    }

    public function start(ListStudentModulesRequest $request, string $id): JsonResponse
    {
        $module = ClassModule::query()->findOrFail($id);

        return ApiResponse::success('Modul berhasil dimulai.', $this->progressService->startModule($request->user(), $module));
    }
}
