<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Dictionary\ListAdminDictionaryEntriesRequest;
use App\Http\Requests\Dictionary\StoreDictionaryEntryRequest;
use App\Http\Requests\Dictionary\UpdateDictionaryEntryRequest;
use App\Http\Resources\DictionaryEntryResource;
use App\Models\DictionaryEntry;
use App\Services\DictionaryEntryService;
use App\Services\DictionaryNormalizer;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class AdminDictionaryEntryController extends Controller
{
    public function __construct(
        private readonly DictionaryEntryService $entryService,
        private readonly DictionaryNormalizer $normalizer,
    ) {}

    public function index(ListAdminDictionaryEntriesRequest $request): JsonResponse
    {
        Gate::authorize('viewAny', DictionaryEntry::class);
        $validated = $request->validated();
        $perPage = (int) ($validated['per_page'] ?? 15);
        $sortBy = $validated['sort_by'] ?? 'indonesia';
        $sortDirection = $validated['sort_direction'] ?? 'asc';
        $search = isset($validated['search']) ? $this->normalizer->normalize($validated['search']) : null;

        $entries = DictionaryEntry::query()
            ->with(['category', 'audioMedia'])
            ->when($validated['category_id'] ?? null, fn ($query, $categoryId) => $query->where('category_id', $categoryId))
            ->when($validated['status'] ?? null, fn ($query, $status) => $query->where('status', $status))
            ->when(array_key_exists('has_audio', $validated), fn ($query) => $validated['has_audio'] ? $query->whereNotNull('audio_media_id') : $query->whereNull('audio_media_id'))
            ->when($search, function ($query) use ($search) {
                $query->where(function ($inner) use ($search) {
                    $inner->where('indonesia_normalized', 'ilike', "%{$search}%")
                        ->orWhere('english_normalized', 'ilike', "%{$search}%")
                        ->orWhere('mekongga_normalized', 'ilike', "%{$search}%");
                });
            })
            ->orderBy($sortBy, $sortDirection)
            ->paginate($perPage);

        return ApiResponse::paginated('Data entri kamus berhasil diambil.', $entries, DictionaryEntryResource::collection($entries->getCollection())->resolve());
    }

    public function store(StoreDictionaryEntryRequest $request): JsonResponse
    {
        Gate::authorize('create', DictionaryEntry::class);
        $entry = $this->entryService->create($request->validated(), $request->user(), $request);

        return ApiResponse::success('Entri kamus berhasil dibuat.', new DictionaryEntryResource($entry), 201);
    }

    public function show(string $id): JsonResponse
    {
        $entry = DictionaryEntry::query()->with(['category', 'audioMedia', 'sentenceExamples'])->findOrFail($id);
        Gate::authorize('view', $entry);

        return ApiResponse::success('Detail entri kamus berhasil diambil.', new DictionaryEntryResource($entry));
    }

    public function update(UpdateDictionaryEntryRequest $request, string $id): JsonResponse
    {
        $entry = DictionaryEntry::query()->findOrFail($id);
        Gate::authorize('update', $entry);
        $entry = $this->entryService->update($entry, $request->validated(), $request->user(), $request);

        return ApiResponse::success('Entri kamus berhasil diperbarui.', new DictionaryEntryResource($entry));
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $entry = DictionaryEntry::query()->findOrFail($id);
        Gate::authorize('delete', $entry);
        $this->entryService->delete($entry, $request->user(), $request);

        return ApiResponse::success('Entri kamus berhasil dihapus.', []);
    }
}
