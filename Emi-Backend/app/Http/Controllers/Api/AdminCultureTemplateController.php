<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Culture\ListCultureTemplatesRequest;
use App\Http\Requests\Culture\StoreCultureTemplateRequest;
use App\Http\Requests\Culture\UpdateCultureTemplateRequest;
use App\Http\Resources\CultureTemplateResource;
use App\Models\CultureTemplate;
use App\Services\CultureTemplateService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class AdminCultureTemplateController extends Controller
{
    public function __construct(private readonly CultureTemplateService $service) {}

    public function index(ListCultureTemplatesRequest $request): JsonResponse
    {
        Gate::authorize('viewAny', CultureTemplate::class);
        $validated = $request->validated();
        $perPage = (int) ($validated['per_page'] ?? 15);
        $sortBy = $validated['sort_by'] ?? 'created_at';
        $sortDirection = $validated['sort_direction'] ?? 'desc';

        $templates = CultureTemplate::query()
            ->withCount('items')
            ->when($validated['search'] ?? null, fn ($query, $search) => $query->where(fn ($inner) => $inner->where('title', 'ilike', "%{$search}%")->orWhere('description', 'ilike', "%{$search}%")))
            ->when($validated['status'] ?? null, fn ($query, $status) => $query->where('status', $status))
            ->when($validated['created_by'] ?? null, fn ($query, $createdBy) => $query->where('created_by', $createdBy))
            ->orderBy($sortBy, $sortDirection)
            ->paginate($perPage);

        return ApiResponse::paginated('Data template budaya berhasil diambil.', $templates, CultureTemplateResource::collection($templates->getCollection())->resolve());
    }

    public function store(StoreCultureTemplateRequest $request): JsonResponse
    {
        Gate::authorize('create', CultureTemplate::class);

        return ApiResponse::success('Template budaya berhasil dibuat.', new CultureTemplateResource($this->service->create($request->validated(), $request->user(), $request)), 201);
    }

    public function show(string $id): JsonResponse
    {
        $template = CultureTemplate::query()->with('items.media')->findOrFail($id);
        Gate::authorize('view', $template);

        return ApiResponse::success('Detail template budaya berhasil diambil.', new CultureTemplateResource($template));
    }

    public function update(UpdateCultureTemplateRequest $request, string $id): JsonResponse
    {
        $template = CultureTemplate::query()->findOrFail($id);
        Gate::authorize('update', $template);

        return ApiResponse::success('Template budaya berhasil diperbarui.', new CultureTemplateResource($this->service->update($template, $request->validated(), $request->user(), $request)));
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $template = CultureTemplate::query()->findOrFail($id);
        Gate::authorize('delete', $template);
        $this->service->delete($template, $request->user(), $request);

        return ApiResponse::success('Template budaya berhasil dihapus.', []);
    }

    public function publish(Request $request, string $id): JsonResponse
    {
        $template = CultureTemplate::query()->findOrFail($id);
        Gate::authorize('update', $template);

        return ApiResponse::success('Template budaya berhasil dipublish.', new CultureTemplateResource($this->service->publish($template, $request->user(), $request)));
    }
}
