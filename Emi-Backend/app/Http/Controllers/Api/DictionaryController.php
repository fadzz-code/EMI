<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Dictionary\ListDictionaryRequest;
use App\Http\Resources\DictionaryCategoryResource;
use App\Http\Resources\DictionaryEntryResource;
use App\Models\DictionaryCategory;
use App\Models\DictionaryEntry;
use App\Services\DictionaryNormalizer;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Gate;

class DictionaryController extends Controller
{
    public function __construct(private readonly DictionaryNormalizer $normalizer) {}

    public function categories(): JsonResponse
    {
        Gate::authorize('viewAny', DictionaryCategory::class);

        $categories = DictionaryCategory::query()
            ->active()
            ->withCount(['entries' => fn ($query) => $query->active()])
            ->orderBy('name')
            ->orderBy('id')
            ->get();

        return ApiResponse::success('Kategori kamus berhasil diambil.', DictionaryCategoryResource::collection($categories));
    }

    public function index(ListDictionaryRequest $request): JsonResponse
    {
        Gate::authorize('viewAny', DictionaryEntry::class);

        $validated = $request->validated();
        $perPage = (int) ($validated['per_page'] ?? 15);
        $sortBy = $validated['sort_by'] ?? 'indonesia';
        $sortColumn = $sortBy === 'indonesia' ? 'indonesia_normalized' : $sortBy;
        $sortDirection = $validated['sort_direction'] ?? 'asc';
        $search = isset($validated['search']) ? $this->normalizer->normalize($validated['search']) : null;
        $language = $validated['language'] ?? 'all';

        $entries = DictionaryEntry::query()
            ->with(['category', 'audioMedia'])
            ->active()
            ->whereHas('category', fn ($query) => $query->active())
            ->when($validated['category_id'] ?? null, fn ($query, $categoryId) => $query->where('category_id', $categoryId))
            ->when($validated['letter'] ?? null, fn ($query, $letter) => $query->where('indonesia_normalized', 'ilike', $this->normalizer->normalize($letter).'%'))
            ->when($search, function ($query) use ($search, $language) {
                $columns = $language === 'all'
                    ? ['indonesia_normalized', 'english_normalized', 'mekongga_normalized']
                    : ["{$language}_normalized"];

                $query->where(function ($inner) use ($columns, $search) {
                    foreach ($columns as $column) {
                        $inner->orWhere($column, 'ilike', "%{$search}%");
                    }
                });
            })
            ->orderBy($sortColumn, $sortDirection)
            ->orderBy('id', $sortDirection)
            ->paginate($perPage);

        return ApiResponse::paginated('Data kamus berhasil diambil.', $entries, DictionaryEntryResource::collection($entries->getCollection())->resolve());
    }

    public function show(string $id): JsonResponse
    {
        $entry = DictionaryEntry::query()
            ->with([
                'category',
                'audioMedia',
                'sentenceExamples' => fn ($query) => $query->where('status', 'active')->with('audioMedia')->orderBy('id'),
            ])
            ->active()
            ->whereHas('category', fn ($query) => $query->active())
            ->findOrFail($id);

        Gate::authorize('view', $entry);

        return ApiResponse::success('Detail kamus berhasil diambil.', new DictionaryEntryResource($entry));
    }
}
