<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\DictionaryCategory;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class DictionaryCategoryService
{
    public function __construct(private readonly AuditLogService $auditLogService) {}

    public function create(array $data, User $admin, Request $request): DictionaryCategory
    {
        return DB::transaction(function () use ($data, $admin, $request) {
            try {
                $category = DictionaryCategory::query()->create([
                    'name' => trim($data['name']),
                    'slug' => $this->uniqueSlug($data['name']),
                    'description' => $data['description'] ?? null,
                    'status' => $data['status'] ?? 'active',
                    'created_by' => $admin->id,
                ]);
            } catch (QueryException $e) {
                throw new ApiException('Nama kategori sudah digunakan.', 'DICTIONARY_CATEGORY_DUPLICATE', 409);
            }

            $this->auditLogService->record('dictionary.category_created', $category, $admin, null, $category->only(['name', 'status']), [], $request);

            return $category;
        });
    }

    public function update(DictionaryCategory $category, array $data, User $admin, Request $request): DictionaryCategory
    {
        return DB::transaction(function () use ($category, $data, $admin, $request) {
            $category = DictionaryCategory::query()->whereKey($category->id)->lockForUpdate()->firstOrFail();
            $oldValues = $category->only(['name', 'slug', 'description', 'status']);
            $oldStatus = $category->status;
            $newStatus = $data['status'] ?? $category->status;

            if ($oldStatus === 'active' && $newStatus === 'inactive' && $category->entries()->active()->exists()) {
                throw new ApiException('Kategori masih memiliki entri aktif.', 'CATEGORY_HAS_ACTIVE_ENTRIES', 409);
            }

            try {
                $category->fill([
                    'name' => isset($data['name']) ? trim($data['name']) : $category->name,
                    'description' => array_key_exists('description', $data) ? $data['description'] : $category->description,
                    'status' => $newStatus,
                    'updated_by' => $admin->id,
                ]);

                if (isset($data['name']) && $data['name'] !== $category->getOriginal('name')) {
                    $category->slug = $this->uniqueSlug($data['name'], $category->id);
                }

                $category->save();
            } catch (QueryException $e) {
                throw new ApiException('Nama kategori sudah digunakan.', 'DICTIONARY_CATEGORY_DUPLICATE', 409);
            }

            $action = match (true) {
                $oldStatus === 'active' && $category->status === 'inactive' => 'dictionary.category_deactivated',
                $oldStatus === 'inactive' && $category->status === 'active' => 'dictionary.category_reactivated',
                default => 'dictionary.category_updated',
            };

            $this->auditLogService->record($action, $category, $admin, $oldValues, $category->only(['name', 'slug', 'description', 'status']), [], $request);

            return $category;
        });
    }

    public function delete(DictionaryCategory $category, User $admin, Request $request): DictionaryCategory
    {
        return DB::transaction(function () use ($category, $admin, $request) {
            $category = DictionaryCategory::query()->whereKey($category->id)->lockForUpdate()->firstOrFail();

            $oldValues = $category->only(['status']);
            $category->forceFill(['status' => 'inactive', 'updated_by' => $admin->id])->save();
            $category->delete();
            $this->auditLogService->record('dictionary.category_deleted', $category, $admin, $oldValues, ['status' => 'inactive'], [], $request);

            return $category;
        });
    }

    private function uniqueSlug(string $name, ?string $ignoreId = null): string
    {
        $base = Str::slug($name) ?: Str::uuid()->toString();
        $slug = $base;
        $counter = 2;

        while (DictionaryCategory::withTrashed()
            ->where('slug', $slug)
            ->when($ignoreId, fn ($query) => $query->whereKeyNot($ignoreId))
            ->exists()) {
            $slug = "{$base}-{$counter}";
            $counter++;
        }

        return $slug;
    }
}
