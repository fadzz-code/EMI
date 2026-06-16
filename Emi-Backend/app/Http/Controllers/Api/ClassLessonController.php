<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Learning\ReorderLessonsRequest;
use App\Http\Requests\Learning\StoreClassLessonRequest;
use App\Http\Requests\Learning\UpdateClassLessonRequest;
use App\Http\Resources\ClassLessonResource;
use App\Models\ClassLesson;
use App\Models\ClassModule;
use App\Services\ClassLessonService;
use App\Services\LessonContentAccessService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class ClassLessonController extends Controller
{
    public function __construct(
        private readonly ClassLessonService $service,
        private readonly LessonContentAccessService $contentAccessService,
    ) {}

    public function index(string $classModuleId): JsonResponse
    {
        $module = ClassModule::query()->findOrFail($classModuleId);
        Gate::authorize('update', $module);
        $lessons = $module->lessons()->with('media')->paginate(100);

        return ApiResponse::paginated('Data materi kelas berhasil diambil.', $lessons, ClassLessonResource::collection($lessons->getCollection())->resolve());
    }

    public function store(StoreClassLessonRequest $request, string $classModuleId): JsonResponse
    {
        $module = ClassModule::query()->findOrFail($classModuleId);
        Gate::authorize('createForModule', [ClassLesson::class, $module]);

        return ApiResponse::success('Materi kelas berhasil dibuat.', new ClassLessonResource($this->service->create($module, $request->validated(), $request->user(), $request)), 201);
    }

    public function show(string $id): JsonResponse
    {
        $lesson = ClassLesson::query()->with('media', 'classModule')->findOrFail($id);
        Gate::authorize('view', $lesson);

        return ApiResponse::success('Detail materi kelas berhasil diambil.', new ClassLessonResource($lesson));
    }

    public function update(UpdateClassLessonRequest $request, string $id): JsonResponse
    {
        $lesson = ClassLesson::query()->findOrFail($id);
        Gate::authorize('update', $lesson);

        return ApiResponse::success('Materi kelas berhasil diperbarui.', new ClassLessonResource($this->service->update($lesson, $request->validated(), $request->user(), $request)));
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $lesson = ClassLesson::query()->findOrFail($id);
        Gate::authorize('delete', $lesson);
        $this->service->delete($lesson, $request->user(), $request);

        return ApiResponse::success('Materi kelas berhasil dihapus.', []);
    }

    public function publish(Request $request, string $id): JsonResponse
    {
        $lesson = ClassLesson::query()->findOrFail($id);
        Gate::authorize('update', $lesson);

        return ApiResponse::success('Materi kelas berhasil dipublish.', new ClassLessonResource($this->service->publish($lesson, $request->user(), $request)));
    }

    public function archive(Request $request, string $id): JsonResponse
    {
        $lesson = ClassLesson::query()->findOrFail($id);
        Gate::authorize('update', $lesson);

        return ApiResponse::success('Materi kelas berhasil diarsipkan.', new ClassLessonResource($this->service->archive($lesson, $request->user(), $request)));
    }

    public function reorder(ReorderLessonsRequest $request, string $classModuleId): JsonResponse
    {
        $module = ClassModule::query()->findOrFail($classModuleId);
        Gate::authorize('update', $module);
        $this->service->reorder($module, $request->validated('lesson_ids'), $request->user(), $request);

        return ApiResponse::success('Urutan materi kelas berhasil diperbarui.', []);
    }

    public function contentUrl(Request $request, string $id): JsonResponse
    {
        $lesson = ClassLesson::query()->with('media', 'classModule.schoolClass.school')->findOrFail($id);

        return ApiResponse::success('Konten materi berhasil diambil.', $this->contentAccessService->content($request->user(), $lesson));
    }
}
