<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Dictionary\ListDictionaryCategoriesRequest;
use App\Http\Requests\Dictionary\StoreDictionaryCategoryRequest;
use App\Http\Requests\Dictionary\UpdateDictionaryCategoryRequest;
use App\Http\Resources\DictionaryCategoryResource;
use App\Models\DictionaryCategory;
use App\Services\DictionaryCategoryService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;

class AdminDictionaryCategoryController extends Controller
{
    public function __construct(private readonly DictionaryCategoryService $categoryService) {}

    public function index(ListDictionaryCategoriesRequest $request): JsonResponse
    {
        Gate::authorize('viewAny', DictionaryCategory::class);
        $validated = $request->validated();
        $perPage = (int) ($validated['per_page'] ?? 15);

        $categories = DictionaryCategory::query()
            ->withCount('entries')
            ->when($validated['status'] ?? null, fn ($query, $status) => $query->where('status', $status))
            ->when($validated['search'] ?? null, fn ($query, $search) => $query->where('name', 'ilike', "%{$search}%"))
            ->orderBy('name')
            ->paginate($perPage);

        return ApiResponse::paginated('Data kategori kamus berhasil diambil.', $categories, DictionaryCategoryResource::collection($categories->getCollection())->resolve());
    }

    public function store(StoreDictionaryCategoryRequest $request): JsonResponse
    {
        Gate::authorize('create', DictionaryCategory::class);
        $category = $this->categoryService->create($request->validated(), $request->user(), $request);

        return ApiResponse::success('Kategori kamus berhasil dibuat.', new DictionaryCategoryResource($category), 201);
    }

    public function show(string $id): JsonResponse
    {
        $category = DictionaryCategory::query()->withCount('entries')->findOrFail($id);
        Gate::authorize('view', $category);

        return ApiResponse::success('Detail kategori kamus berhasil diambil.', new DictionaryCategoryResource($category));
    }

    public function update(UpdateDictionaryCategoryRequest $request, string $id): JsonResponse
    {
        $category = DictionaryCategory::query()->findOrFail($id);
        Gate::authorize('update', $category);
        $category = $this->categoryService->update($category, $request->validated(), $request->user(), $request);

        return ApiResponse::success('Kategori kamus berhasil diperbarui.', new DictionaryCategoryResource($category));
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        $category = DictionaryCategory::query()->findOrFail($id);
        Gate::authorize('delete', $category);
        $this->categoryService->delete($category, $request->user(), $request);

        return ApiResponse::success('Kategori kamus berhasil dinonaktifkan.', []);
    }
}
