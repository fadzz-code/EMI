<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Learning\ReorderLessonsRequest;
use App\Http\Requests\Learning\StoreLessonTemplateRequest;
use App\Http\Requests\Learning\UpdateLessonTemplateRequest;
use App\Http\Resources\LessonTemplateResource;
use App\Models\LessonTemplate;
use App\Models\ModuleTemplate;
use App\Services\LessonTemplateService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class AdminLessonTemplateController extends Controller
{
    public function __construct(private readonly LessonTemplateService $service) {}

    public function index(string $moduleTemplateId): JsonResponse
    {
        Gate::authorize('viewAny', LessonTemplate::class);
        $module = ModuleTemplate::query()->findOrFail($moduleTemplateId);
        $lessons = $module->lessons()->with('media')->paginate(100);

        return ApiResponse::paginated('Data materi template berhasil diambil.', $lessons, LessonTemplateResource::collection($lessons->getCollection())->resolve());
    }

    public function store(StoreLessonTemplateRequest $request, string $moduleTemplateId): JsonResponse
    {
        Gate::authorize('create', LessonTemplate::class);
        $module = ModuleTemplate::query()->findOrFail($moduleTemplateId);

        return ApiResponse::success('Materi template berhasil dibuat.', new LessonTemplateResource($this->service->create($module, $request->validated(), $request->user(), $request)), 201);
    }

    public function show(string $id): JsonResponse
    {
        $lesson = LessonTemplate::query()->with('media')->findOrFail($id);
        Gate::authorize('view', $lesson);

        return ApiResponse::success('Detail materi template berhasil diambil.', new LessonTemplateResource($lesson));
    }

    public function update(UpdateLessonTemplateRequest $request, string $id): JsonResponse
    {
        $lesson = LessonTemplate::query()->findOrFail($id);
        Gate::authorize('update', $lesson);

        return ApiResponse::success('Materi template berhasil diperbarui.', new LessonTemplateResource($this->service->update($lesson, $request->validated(), $request->user(), $request)));
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $lesson = LessonTemplate::query()->findOrFail($id);
        Gate::authorize('delete', $lesson);
        $this->service->delete($lesson, $request->user(), $request);

        return ApiResponse::success('Materi template berhasil dihapus.', []);
    }

    public function publish(Request $request, string $id): JsonResponse
    {
        $lesson = LessonTemplate::query()->findOrFail($id);
        Gate::authorize('update', $lesson);

        return ApiResponse::success('Materi template berhasil dipublish.', new LessonTemplateResource($this->service->publish($lesson, $request->user(), $request)));
    }

    public function archive(Request $request, string $id): JsonResponse
    {
        $lesson = LessonTemplate::query()->findOrFail($id);
        Gate::authorize('update', $lesson);

        return ApiResponse::success('Materi template berhasil diarsipkan.', new LessonTemplateResource($this->service->archive($lesson, $request->user(), $request)));
    }

    public function reorder(ReorderLessonsRequest $request, string $moduleTemplateId): JsonResponse
    {
        $module = ModuleTemplate::query()->findOrFail($moduleTemplateId);
        Gate::authorize('update', $module);
        $this->service->reorder($module, $request->validated('lesson_ids'), $request->user(), $request);

        return ApiResponse::success('Urutan materi template berhasil diperbarui.', []);
    }
}
