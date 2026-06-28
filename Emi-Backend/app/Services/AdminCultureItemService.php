<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\ClassCultureItem;
use App\Models\MediaFile;
use App\Models\SchoolClass;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class AdminCultureItemService
{
    public function __construct(private readonly AuditLogService $auditLogService) {}

    public function list(): array
    {
        return ClassCultureItem::query()
            ->where('created_scope', 'admin')
            ->whereNotNull('admin_group_id')
            ->with('media')
            ->orderBy('display_order')
            ->orderBy('created_at')
            ->get()
            ->groupBy('admin_group_id')
            ->map(fn ($items, $groupId) => $this->groupPayload((string) $groupId, $items))
            ->values()
            ->all();
    }

    public function show(string $groupId): array
    {
        $items = $this->groupItems($groupId);

        return $this->groupPayload($groupId, $items);
    }

    public function create(array $data, User $actor, Request $request): array
    {
        $this->validateContent($data);
        $classes = $this->activeClasses();

        if ($classes->isEmpty()) {
            throw new ApiException('Belum ada kelas aktif untuk menerima konten budaya.', 'NO_ACTIVE_CLASSES', 409);
        }

        $groupId = (string) Str::uuid();

        DB::transaction(function () use ($classes, $data, $actor, $request, $groupId) {
            foreach ($classes as $class) {
                ClassCultureItem::query()->create($this->attributesForClass($class->id, $groupId, $data, $actor));
            }

            $this->auditLogService->record('admin_culture_item.created', ClassCultureItem::query()->where('admin_group_id', $groupId)->first(), $actor, null, ['admin_group_id' => $groupId], [], $request);
        });

        return $this->show($groupId);
    }

    public function update(string $groupId, array $data, User $actor, Request $request): array
    {
        $items = $this->groupItems($groupId);
        $merged = array_merge($items->first()->toArray(), $data);
        $this->validateContent($merged);

        DB::transaction(function () use ($items, $data, $actor, $request, $groupId) {
            foreach ($items as $item) {
                $item->fill(collect($data)->only(['title', 'description', 'content_type', 'media_id', 'external_url', 'display_order', 'status'])->all());
                $item->updated_by = $actor->id;
                $this->applyStatusTimestamps($item);
                $item->save();
            }

            $this->auditLogService->record('admin_culture_item.updated', $items->first(), $actor, null, ['admin_group_id' => $groupId], [], $request);
        });

        return $this->show($groupId);
    }

    public function publish(string $groupId, User $actor, Request $request): array
    {
        return $this->setStatus($groupId, 'published', $actor, $request, 'admin_culture_item.published');
    }

    public function archive(string $groupId, User $actor, Request $request): array
    {
        return $this->setStatus($groupId, 'archived', $actor, $request, 'admin_culture_item.archived');
    }

    public function delete(string $groupId, User $actor, Request $request): void
    {
        $items = $this->groupItems($groupId);

        DB::transaction(function () use ($items, $actor, $request, $groupId) {
            foreach ($items as $item) {
                $item->delete();
            }

            $this->auditLogService->record('admin_culture_item.deleted', $items->first(), $actor, null, ['admin_group_id' => $groupId], [], $request);
        });
    }

    private function setStatus(string $groupId, string $status, User $actor, Request $request, string $event): array
    {
        $items = $this->groupItems($groupId);

        DB::transaction(function () use ($items, $status, $actor, $request, $groupId, $event) {
            foreach ($items as $item) {
                $item->status = $status;
                $item->updated_by = $actor->id;
                $this->applyStatusTimestamps($item);
                $item->save();
            }

            $this->auditLogService->record($event, $items->first(), $actor, null, ['admin_group_id' => $groupId, 'status' => $status], [], $request);
        });

        return $this->show($groupId);
    }

    private function attributesForClass(string $classId, string $groupId, array $data, User $actor): array
    {
        return [
            'class_id' => $classId,
            'admin_group_id' => $groupId,
            'created_scope' => 'admin',
            'title' => $data['title'],
            'description' => $data['description'] ?? null,
            'content_type' => $data['content_type'],
            'media_id' => $data['media_id'] ?? null,
            'external_url' => $data['external_url'] ?? null,
            'display_order' => $data['display_order'] ?? 1,
            'status' => $data['status'] ?? 'draft',
            'created_by' => $actor->id,
            'published_at' => ($data['status'] ?? 'draft') === 'published' ? now() : null,
            'archived_at' => ($data['status'] ?? 'draft') === 'archived' ? now() : null,
        ];
    }

    private function groupPayload(string $groupId, $items): array
    {
        $first = $items->first();

        return [
            'id' => $groupId,
            'admin_group_id' => $groupId,
            'title' => $first->title,
            'description' => $first->description,
            'content_type' => $first->content_type,
            'media_id' => $first->media_id,
            'media' => $first->relationLoaded('media') ? new \App\Http\Resources\MediaFileResource($first->media) : null,
            'external_url' => $first->external_url,
            'display_order' => $first->display_order,
            'status' => $first->status,
            'created_scope' => 'admin',
            'classes_count' => $items->count(),
            'published_classes_count' => $items->where('status', 'published')->count(),
            'created_at' => $first->created_at?->toISOString(),
            'updated_at' => $items->max('updated_at')?->toISOString(),
        ];
    }

    private function groupItems(string $groupId)
    {
        $items = ClassCultureItem::query()
            ->where('created_scope', 'admin')
            ->where('admin_group_id', $groupId)
            ->with('media')
            ->get();

        if ($items->isEmpty()) {
            throw new ApiException('Konten budaya admin tidak ditemukan.', 'ADMIN_CULTURE_ITEM_NOT_FOUND', 404);
        }

        return $items;
    }

    private function activeClasses()
    {
        return SchoolClass::query()
            ->where('status', 'active')
            ->whereHas('school', fn ($query) => $query->where('status', 'active'))
            ->get();
    }

    private function validateContent(array $data): void
    {
        $type = $data['content_type'] ?? null;
        if (in_array($type, ['image', 'audio', 'pdf', 'video'], true) && empty($data['media_id'])) {
            throw new ApiException('Media wajib diisi untuk tipe konten file.', 'VALIDATION_ERROR', 422);
        }
        if (in_array($type, ['image', 'audio', 'pdf', 'video'], true) && ! empty($data['media_id'])) {
            $media = MediaFile::query()->find($data['media_id']);
            if (! $media || $media->purpose !== 'culture_media') {
                throw new ApiException('Media budaya harus menggunakan purpose culture_media.', 'VALIDATION_ERROR', 422);
            }
        }
        if (in_array($type, ['youtube', 'article', 'link'], true) && empty($data['external_url'])) {
            throw new ApiException('URL wajib diisi untuk tipe konten tautan.', 'VALIDATION_ERROR', 422);
        }
    }

    private function applyStatusTimestamps(ClassCultureItem $item): void
    {
        if ($item->status === 'published' && $item->published_at === null) {
            $item->published_at = now();
            $item->archived_at = null;
        }

        if ($item->status === 'archived' && $item->archived_at === null) {
            $item->archived_at = now();
        }
    }
}
