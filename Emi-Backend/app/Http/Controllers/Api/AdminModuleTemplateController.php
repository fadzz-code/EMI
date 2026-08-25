<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Learning\ListModuleTemplatesRequest;
use App\Http\Requests\Learning\PublishModuleTemplateRequest;
use App\Http\Requests\Learning\StoreModuleTemplateRequest;
use App\Http\Requests\Learning\UpdateModuleTemplateRequest;
use App\Http\Resources\ModuleTemplateResource;
use App\Models\ModuleTemplate;
use App\Models\SchoolClass;
use App\Services\ModuleTemplateApplyService;
use App\Services\ModuleTemplateService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class AdminModuleTemplateController extends Controller
{
    public function __construct(
        private readonly ModuleTemplateService $service,
        private readonly ModuleTemplateApplyService $applyService,
    ) {}

    public function index(ListModuleTemplatesRequest $request): JsonResponse
    {
        Gate::authorize('viewAny', ModuleTemplate::class);
        $validated = $request->validated();
        $perPage = (int) ($validated['per_page'] ?? 15);
        $sortBy = $validated['sort_by'] ?? 'created_at';
        $sortDirection = $validated['sort_direction'] ?? 'desc';

        $templates = ModuleTemplate::query()
            ->withCount('lessons')
            ->when($validated['search'] ?? null, fn ($query, $search) => $query->where(fn ($inner) => $inner->where('title', 'ilike', "%{$search}%")->orWhere('description', 'ilike', "%{$search}%")))
            ->when($validated['status'] ?? null, fn ($query, $status) => $query->where('status', $status))
            ->when($validated['created_by'] ?? null, fn ($query, $createdBy) => $query->where('created_by', $createdBy))
            ->orderBy($sortBy, $sortDirection)
            ->paginate($perPage);

        return ApiResponse::paginated('Data template modul berhasil diambil.', $templates, ModuleTemplateResource::collection($templates->getCollection())->resolve());
    }

    public function store(StoreModuleTemplateRequest $request): JsonResponse
    {
        Gate::authorize('create', ModuleTemplate::class);

        return ApiResponse::success('Template modul berhasil dibuat.', new ModuleTemplateResource($this->service->create($request->validated(), $request->user(), $request)), 201);
    }

    public function show(string $id): JsonResponse
    {
        $template = ModuleTemplate::query()->with('lessons.media')->findOrFail($id);
        Gate::authorize('view', $template);

        return ApiResponse::success('Detail template modul berhasil diambil.', new ModuleTemplateResource($template));
    }

    public function update(UpdateModuleTemplateRequest $request, string $id): JsonResponse
    {
        $template = ModuleTemplate::query()->findOrFail($id);
        Gate::authorize('update', $template);

        return ApiResponse::success('Template modul berhasil diperbarui.', new ModuleTemplateResource($this->service->update($template, $request->validated(), $request->user(), $request)));
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $template = ModuleTemplate::query()->findOrFail($id);
        Gate::authorize('delete', $template);
        $this->service->delete($template, $request->user(), $request);

        return ApiResponse::success('Template modul berhasil dihapus.', []);
    }

    public function publish(PublishModuleTemplateRequest $request, string $id): JsonResponse
    {
        $template = ModuleTemplate::query()->findOrFail($id);
        Gate::authorize('update', $template);
        $template = $this->service->publish($template, $request->user(), $request);
        $distribution = null;

        if ($request->validated('apply_to_all_active_classes', false)) {
            $classIds = SchoolClass::query()
                ->where('status', 'active')
                ->whereHas('school', fn ($query) => $query->where('status', 'active'))
                ->pluck('id')
                ->all();
            $distribution = $this->applyService->apply(
                $template,
                $classIds,
                $request->user(),
                $request,
                false,
                (bool) $request->validated('publish_class_modules', false),
            );
        }

        $data = (new ModuleTemplateResource($template))->resolve();
        $data['distribution'] = $distribution;

        return ApiResponse::success('Template modul berhasil dipublish.', $data);
    }

    public function archive(Request $request, string $id): JsonResponse
    {
        $template = ModuleTemplate::query()->findOrFail($id);
        Gate::authorize('update', $template);

        return ApiResponse::success('Template modul berhasil diarsipkan.', new ModuleTemplateResource($this->service->archive($template, $request->user(), $request)));
    }
}
