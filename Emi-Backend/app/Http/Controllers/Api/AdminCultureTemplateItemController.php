<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Culture\StoreCultureTemplateItemRequest;
use App\Http\Requests\Culture\UpdateCultureTemplateItemRequest;
use App\Http\Resources\CultureTemplateItemResource;
use App\Models\CultureTemplate;
use App\Models\CultureTemplateItem;
use App\Services\CultureTemplateItemService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class AdminCultureTemplateItemController extends Controller
{
    public function __construct(private readonly CultureTemplateItemService $service) {}

    public function store(StoreCultureTemplateItemRequest $request, string $cultureTemplateId): JsonResponse
    {
        $template = CultureTemplate::query()->findOrFail($cultureTemplateId);
        Gate::authorize('update', $template);

        return ApiResponse::success('Item budaya berhasil dibuat.', new CultureTemplateItemResource($this->service->create($template, $request->validated(), $request->user(), $request)), 201);
    }

    public function show(string $id): JsonResponse
    {
        $item = CultureTemplateItem::query()->with('media')->findOrFail($id);
        Gate::authorize('view', $item);

        return ApiResponse::success('Detail item budaya berhasil diambil.', new CultureTemplateItemResource($item));
    }

    public function update(UpdateCultureTemplateItemRequest $request, string $id): JsonResponse
    {
        $item = CultureTemplateItem::query()->findOrFail($id);
        Gate::authorize('update', $item);

        return ApiResponse::success('Item budaya berhasil diperbarui.', new CultureTemplateItemResource($this->service->update($item, $request->validated(), $request->user(), $request)));
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $item = CultureTemplateItem::query()->findOrFail($id);
        Gate::authorize('delete', $item);
        $this->service->delete($item, $request->user(), $request);

        return ApiResponse::success('Item budaya berhasil dihapus.', []);
    }
}
