<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Ai\ExtractSourceAiKnowledgeRequest;
use App\Http\Requests\Ai\ListAiKnowledgeItemsRequest;
use App\Http\Requests\Ai\StoreAiKnowledgeItemRequest;
use App\Http\Requests\Ai\UpdateAiKnowledgeItemRequest;
use App\Http\Resources\AiKnowledgeItemResource;
use App\Models\AiKnowledgeItem;
use App\Services\AiKnowledgeService;
use App\Services\AiSourceIngestionService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class AdminAiKnowledgeController extends Controller
{
    public function __construct(
        private readonly AiKnowledgeService $service,
        private readonly AiSourceIngestionService $ingestionService
    ) {}

    public function index(ListAiKnowledgeItemsRequest $request): JsonResponse
    {
        Gate::authorize('viewAny', AiKnowledgeItem::class);
        $validated = $request->validated();
        $perPage = (int) ($validated['per_page'] ?? 15);
        $sortBy = $validated['sort_by'] ?? 'created_at';
        $sortDirection = $validated['sort_direction'] ?? 'desc';

        $items = AiKnowledgeItem::query()
            ->when($validated['search'] ?? null, fn ($query, $search) => $query->where(fn ($inner) => $inner->where('title', 'ilike', "%{$search}%")->orWhere('category', 'ilike', "%{$search}%")->orWhere('content', 'ilike', "%{$search}%")))
            ->when($validated['category'] ?? null, fn ($query, $category) => $query->where('category', 'ilike', "%{$category}%"))
            ->when($validated['status'] ?? null, fn ($query, $status) => $query->where('status', $status))
            ->orderBy($sortBy, $sortDirection)
            ->paginate($perPage);

        return ApiResponse::paginated('Data Basis AI berhasil diambil.', $items, AiKnowledgeItemResource::collection($items->getCollection())->resolve());
    }

    public function store(StoreAiKnowledgeItemRequest $request): JsonResponse
    {
        Gate::authorize('create', AiKnowledgeItem::class);

        return ApiResponse::success('Basis AI berhasil dibuat.', new AiKnowledgeItemResource($this->service->create($request->validated(), $request->user(), $request)), 201);
    }

    public function show(string $id): JsonResponse
    {
        $item = AiKnowledgeItem::query()->findOrFail($id);
        Gate::authorize('view', $item);

        return ApiResponse::success('Detail Basis AI berhasil diambil.', new AiKnowledgeItemResource($item));
    }

    public function update(UpdateAiKnowledgeItemRequest $request, string $id): JsonResponse
    {
        $item = AiKnowledgeItem::query()->findOrFail($id);
        Gate::authorize('update', $item);

        return ApiResponse::success('Basis AI berhasil diperbarui.', new AiKnowledgeItemResource($this->service->update($item, $request->validated(), $request->user(), $request)));
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $item = AiKnowledgeItem::query()->findOrFail($id);
        Gate::authorize('delete', $item);
        $this->service->delete($item, $request->user(), $request);

        return ApiResponse::success('Basis AI berhasil dihapus.', []);
    }

    public function publish(Request $request, string $id): JsonResponse
    {
        $item = AiKnowledgeItem::query()->findOrFail($id);
        Gate::authorize('update', $item);

        return ApiResponse::success('Basis AI berhasil dipublish.', new AiKnowledgeItemResource($this->service->publish($item, $request->user(), $request)));
    }

    public function archive(Request $request, string $id): JsonResponse
    {
        $item = AiKnowledgeItem::query()->findOrFail($id);
        Gate::authorize('update', $item);

        return ApiResponse::success('Basis AI berhasil diarsipkan.', new AiKnowledgeItemResource($this->service->archive($item, $request->user(), $request)));
    }

    public function extractSource(ExtractSourceAiKnowledgeRequest $request): JsonResponse
    {
        try {
            $data = $this->ingestionService->extract(
                $request->validated('source_type'),
                $request->validated('source_url')
            );

            return ApiResponse::success('Isi sumber berhasil diambil.', $data);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Isi sumber tidak dapat diambil.',
                'errors' => [
                    'source_url' => [$e->getMessage()],
                ],
            ], 422);
        }
    }
}
