<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Learning\ListClassModulesRequest;
use App\Http\Requests\Learning\ReorderClassModulesRequest;
use App\Http\Requests\Learning\StoreClassModuleRequest;
use App\Http\Requests\Learning\UpdateClassModuleRequest;
use App\Http\Resources\ClassModuleResource;
use App\Models\ClassModule;
use App\Models\SchoolClass;
use App\Services\ClassModuleService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class ClassModuleController extends Controller
{
    public function __construct(private readonly ClassModuleService $service) {}

    public function index(ListClassModulesRequest $request, string $classId): JsonResponse
    {
        $class = SchoolClass::query()->findOrFail($classId);
        Gate::authorize('createForClass', [ClassModule::class, $class]);
        $validated = $request->validated();
        $perPage = (int) ($validated['per_page'] ?? 15);
        $sortBy = $validated['sort_by'] ?? 'sort_order';
        $sortDirection = $validated['sort_direction'] ?? 'asc';

        $modules = $class->classModules()
            ->when($validated['search'] ?? null, fn ($query, $search) => $query->where(fn ($inner) => $inner->where('title', 'ilike', "%{$search}%")->orWhere('description', 'ilike', "%{$search}%")))
            ->when($validated['status'] ?? null, fn ($query, $status) => $query->where('status', $status))
            ->orderBy($sortBy, $sortDirection)
            ->paginate($perPage);

        return ApiResponse::paginated('Data modul kelas berhasil diambil.', $modules, ClassModuleResource::collection($modules->getCollection())->resolve());
    }

    public function store(StoreClassModuleRequest $request, string $classId): JsonResponse
    {
        $class = SchoolClass::query()->findOrFail($classId);
        Gate::authorize('createForClass', [ClassModule::class, $class]);

        return ApiResponse::success('Modul kelas berhasil dibuat.', new ClassModuleResource($this->service->create($class, $request->validated(), $request->user(), $request)), 201);
    }

    public function show(string $id): JsonResponse
    {
        $module = ClassModule::query()->with('lessons.media')->findOrFail($id);
        Gate::authorize('view', $module);

        return ApiResponse::success('Detail modul kelas berhasil diambil.', new ClassModuleResource($module));
    }

    public function update(UpdateClassModuleRequest $request, string $id): JsonResponse
    {
        $module = ClassModule::query()->findOrFail($id);
        Gate::authorize('update', $module);

        return ApiResponse::success('Modul kelas berhasil diperbarui.', new ClassModuleResource($this->service->update($module, $request->validated(), $request->user(), $request)));
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $module = ClassModule::query()->findOrFail($id);
        Gate::authorize('delete', $module);
        $this->service->delete($module, $request->user(), $request);

        return ApiResponse::success('Modul kelas berhasil dihapus.', []);
    }

    public function publish(Request $request, string $id): JsonResponse
    {
        $module = ClassModule::query()->findOrFail($id);
        Gate::authorize('update', $module);

        return ApiResponse::success('Modul kelas berhasil dipublish.', new ClassModuleResource($this->service->publish($module, $request->user(), $request)));
    }

    public function archive(Request $request, string $id): JsonResponse
    {
        $module = ClassModule::query()->findOrFail($id);
        Gate::authorize('update', $module);

        return ApiResponse::success('Modul kelas berhasil diarsipkan.', new ClassModuleResource($this->service->archive($module, $request->user(), $request)));
    }

    public function reorder(ReorderClassModulesRequest $request, string $classId): JsonResponse
    {
        $class = SchoolClass::query()->findOrFail($classId);
        Gate::authorize('createForClass', [ClassModule::class, $class]);
        $this->service->reorder($class, $request->validated('module_ids'), $request->user(), $request);

        return ApiResponse::success('Urutan modul kelas berhasil diperbarui.', []);
    }
}
