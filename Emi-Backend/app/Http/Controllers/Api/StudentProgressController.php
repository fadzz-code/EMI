<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Learning\UpdateLessonProgressRequest;
use App\Http\Resources\LessonProgressResource;
use App\Http\Resources\ModuleProgressResource;
use App\Models\ClassLesson;
use App\Models\ModuleProgress;
use App\Services\LearningAccessService;
use App\Services\LearningProgressService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StudentProgressController extends Controller
{
    public function __construct(
        private readonly LearningProgressService $progressService,
        private readonly LearningAccessService $accessService,
    ) {}

    public function updateLesson(UpdateLessonProgressRequest $request, string $id): JsonResponse
    {
        $lesson = ClassLesson::query()->with('classModule.schoolClass.school')->findOrFail($id);
        $progress = $this->progressService->updateLessonProgress(
            $request->user(),
            $lesson,
            $request->validated('status'),
            $request->validated('progress_percent'),
        );

        return ApiResponse::success('Progress materi berhasil diperbarui.', new LessonProgressResource($progress));
    }

    public function modules(Request $request): JsonResponse
    {
        $classId = $this->accessService->studentClassId($request->user());
        $progress = ModuleProgress::query()
            ->where('student_id', $request->user()->id)
            ->whereHas('classModule', fn ($query) => $query->where('class_id', $classId))
            ->with('classModule')
            ->paginate(15);

        return ApiResponse::paginated('Progress modul berhasil diambil.', $progress, ModuleProgressResource::collection($progress->getCollection())->resolve());
    }
}
