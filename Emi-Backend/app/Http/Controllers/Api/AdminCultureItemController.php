<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Culture\ListAdminCultureItemsRequest;
use App\Http\Requests\Culture\StoreClassCultureItemRequest;
use App\Http\Requests\Culture\UpdateClassCultureItemRequest;
use App\Http\Resources\AdminCultureItemResource;
use App\Services\AdminCultureItemService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminCultureItemController extends Controller
{
    public function __construct(private readonly AdminCultureItemService $service) {}

    public function index(ListAdminCultureItemsRequest $request): JsonResponse
    {
        $items = $this->service->list($request->validated());

        return ApiResponse::paginated('Data konten budaya admin berhasil diambil.', $items, AdminCultureItemResource::collection($items));
    }

    public function store(StoreClassCultureItemRequest $request): JsonResponse
    {
        return ApiResponse::success('Konten budaya admin berhasil dibuat untuk semua kelas.', $this->service->create($request->validated(), $request->user(), $request), 201);
    }

    public function show(string $groupId): JsonResponse
    {
        return ApiResponse::success('Detail konten budaya admin berhasil diambil.', $this->service->show($groupId));
    }

    public function update(UpdateClassCultureItemRequest $request, string $groupId): JsonResponse
    {
        return ApiResponse::success('Konten budaya admin berhasil diperbarui.', $this->service->update($groupId, $request->validated(), $request->user(), $request));
    }

    public function destroy(Request $request, string $groupId): JsonResponse
    {
        $this->service->delete($groupId, $request->user(), $request);

        return ApiResponse::success('Konten budaya admin berhasil dihapus.', []);
    }

    public function publish(Request $request, string $groupId): JsonResponse
    {
        return ApiResponse::success('Konten budaya admin berhasil dipublish.', $this->service->publish($groupId, $request->user(), $request));
    }

    public function archive(Request $request, string $groupId): JsonResponse
    {
        return ApiResponse::success('Konten budaya admin berhasil diarsipkan.', $this->service->archive($groupId, $request->user(), $request));
    }
}
