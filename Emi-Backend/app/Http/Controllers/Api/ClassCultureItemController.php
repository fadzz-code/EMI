<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Culture\StoreClassCultureItemRequest;
use App\Http\Requests\Culture\UpdateClassCultureItemRequest;
use App\Http\Resources\ClassCultureItemResource;
use App\Models\ClassCultureItem;
use App\Models\SchoolClass;
use App\Services\ClassCultureItemService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class ClassCultureItemController extends Controller
{
    public function __construct(private readonly ClassCultureItemService $service) {}

    public function index(Request $request, string $classId): JsonResponse
    {
        $class = SchoolClass::query()->findOrFail($classId);
        Gate::authorize('createForClass', [ClassCultureItem::class, $class]);

        $perPage = (int) ($request->query('per_page') ?? 15);
        $sortBy = $request->query('sort_by') ?? 'display_order';
        $sortDirection = $request->query('sort_direction') ?? 'asc';

        $items = ClassCultureItem::query()
            ->where('class_id', $classId)
            ->with('media', 'schoolClass.school')
            ->orderBy($sortBy, $sortDirection)
            ->paginate($perPage);

        return ApiResponse::paginated('Data item budaya kelas berhasil diambil.', $items, ClassCultureItemResource::collection($items->getCollection())->resolve());
    }

    public function store(StoreClassCultureItemRequest $request, string $classId): JsonResponse
    {
        $class = SchoolClass::query()->findOrFail($classId);
        Gate::authorize('createForClass', [ClassCultureItem::class, $class]);

        return ApiResponse::success('Item budaya kelas berhasil dibuat.', new ClassCultureItemResource($this->service->create($class, $request->validated(), $request->user(), $request)), 201);
    }

    public function show(string $id): JsonResponse
    {
        $item = ClassCultureItem::query()->with('media', 'schoolClass')->findOrFail($id);
        Gate::authorize('view', $item);

        return ApiResponse::success('Detail item budaya kelas berhasil diambil.', new ClassCultureItemResource($item));
    }

    public function update(UpdateClassCultureItemRequest $request, string $id): JsonResponse
    {
        $item = ClassCultureItem::query()->findOrFail($id);
        Gate::authorize('update', $item);

        return ApiResponse::success('Item budaya kelas berhasil diperbarui.', new ClassCultureItemResource($this->service->update($item, $request->validated(), $request->user(), $request)));
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $item = ClassCultureItem::query()->findOrFail($id);
        Gate::authorize('delete', $item);
        $this->service->delete($item, $request->user(), $request);

        return ApiResponse::success('Item budaya kelas berhasil dihapus.', []);
    }

    public function publish(Request $request, string $id): JsonResponse
    {
        $item = ClassCultureItem::query()->findOrFail($id);
        Gate::authorize('update', $item);

        return ApiResponse::success('Item budaya kelas berhasil dipublish.', new ClassCultureItemResource($this->service->publish($item, $request->user(), $request)));
    }

    public function archive(Request $request, string $id): JsonResponse
    {
        $item = ClassCultureItem::query()->findOrFail($id);
        Gate::authorize('update', $item);

        return ApiResponse::success('Item budaya kelas berhasil diarsipkan.', new ClassCultureItemResource($this->service->archive($item, $request->user(), $request)));
    }
}
