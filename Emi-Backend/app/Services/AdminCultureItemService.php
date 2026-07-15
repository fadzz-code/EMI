<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Http\Resources\MediaFileResource;
use App\Models\AdminCultureItem;
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

    public function list(array $filters)
    {
        return AdminCultureItem::query()
            ->with('media')
            ->withCount([
                'classItems as classes_count',
                'classItems as published_classes_count' => fn ($query) => $query->where('status', 'published'),
            ])
            ->when($filters['search'] ?? null, fn ($query, $search) => $query->where('title', 'like', "%{$search}%"))
            ->when($filters['status'] ?? null, fn ($query, $status) => $query->where('status', $status))
            ->when($filters['content_type'] ?? null, fn ($query, $contentType) => $query->where('content_type', $contentType))
            ->orderBy('display_order')
            ->orderBy('created_at')
            ->paginate($filters['per_page'] ?? 15);
    }

    public function show(string $groupId): array
    {
        return $this->masterPayload($this->masterItem($groupId));
    }

    public function create(array $data, User $actor, Request $request): array
    {
        $this->validateContent($data);
        if (($data['status'] ?? 'draft') === 'published') {
            $this->validatePublishReadiness($data);
        }
        $classes = $this->activeClasses();

        if ($classes->isEmpty()) {
            throw new ApiException('Belum ada kelas aktif untuk menerima konten budaya.', 'NO_ACTIVE_CLASSES', 409);
        }

        $groupId = (string) Str::uuid();

        $master = DB::transaction(function () use ($classes, $data, $actor, $request, $groupId) {
            $master = AdminCultureItem::query()->create($this->masterAttributes($groupId, $data, $actor));

            foreach ($classes as $class) {
                ClassCultureItem::query()->create($this->attributesForClass($class->id, $groupId, $data, $actor));
            }

            $this->auditLogService->record('admin_culture_item.created', $master, $actor, null, ['admin_group_id' => $groupId], [], $request);

            return $master;
        });

        return $this->masterPayload($master->refresh()->load('media'));
    }

    public function update(string $groupId, array $data, User $actor, Request $request): array
    {
        $master = $this->masterItem($groupId);
        $merged = array_merge($master->toArray(), $data);
        $this->validateContent($merged);
        if (($merged['status'] ?? 'draft') === 'published') {
            $this->validatePublishReadiness($merged);
        }

        DB::transaction(function () use ($master, $data, $actor, $request, $groupId) {
            $this->fillCultureItem($master, $data, $actor);
            $master->save();

            foreach ($this->attachedClassItems($groupId) as $item) {
                $this->fillCultureItem($item, $data, $actor);
                $item->save();
            }

            $this->auditLogService->record('admin_culture_item.updated', $master, $actor, null, ['admin_group_id' => $groupId], [], $request);
        });

        return $this->show($groupId);
    }

    public function publish(string $groupId, User $actor, Request $request): array
    {
        $item = $this->masterItem($groupId);
        $this->validatePublishReadiness($item->toArray());

        return $this->setStatus($groupId, 'published', $actor, $request, 'admin_culture_item.published');
    }

    public function archive(string $groupId, User $actor, Request $request): array
    {
        return $this->setStatus($groupId, 'archived', $actor, $request, 'admin_culture_item.archived');
    }

    public function delete(string $groupId, User $actor, Request $request): void
    {
        $master = $this->masterItem($groupId);

        DB::transaction(function () use ($master, $actor, $request, $groupId) {
            foreach ($this->attachedClassItems($groupId) as $item) {
                $item->admin_group_id = null;
                $item->save();
                $item->delete();
            }

            $master->delete();
            $this->auditLogService->record('admin_culture_item.deleted', $master, $actor, null, ['admin_group_id' => $groupId], [], $request);
        });
    }

    private function setStatus(string $groupId, string $status, User $actor, Request $request, string $event): array
    {
        $master = $this->masterItem($groupId);

        DB::transaction(function () use ($master, $status, $actor, $request, $groupId, $event) {
            $master->status = $status;
            $master->updated_by = $actor->id;
            $this->applyStatusTimestamps($master);
            $master->save();

            foreach ($this->attachedClassItems($groupId) as $item) {
                $item->status = $status;
                $item->updated_by = $actor->id;
                $this->applyStatusTimestamps($item);
                $item->save();
            }

            $this->auditLogService->record($event, $master, $actor, null, ['admin_group_id' => $groupId, 'status' => $status], [], $request);
        });

        return $this->show($groupId);
    }

    private function masterAttributes(string $groupId, array $data, User $actor): array
    {
        return [
            'admin_group_id' => $groupId,
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

    private function fillCultureItem(AdminCultureItem|ClassCultureItem $item, array $data, User $actor): void
    {
        $item->fill(collect($data)->only(['title', 'description', 'content_type', 'media_id', 'external_url', 'display_order', 'status'])->all());
        $item->updated_by = $actor->id;
        $this->applyStatusTimestamps($item);
    }

    private function masterPayload(AdminCultureItem $item): array
    {
        $attachedItems = $this->attachedClassItems($item->admin_group_id);

        return [
            'id' => $item->admin_group_id,
            'title' => $item->title,
            'description' => $item->description,
            'content_type' => $item->content_type,
            'media' => $item->relationLoaded('media') && $item->media ? new MediaFileResource($item->media) : null,
            'external_url' => $item->external_url,
            'display_order' => $item->display_order,
            'status' => $item->status,
            'classes_count' => $attachedItems->count(),
            'published_classes_count' => $attachedItems->where('status', 'published')->count(),
            'created_at' => $item->created_at?->toISOString(),
            'updated_at' => $item->updated_at?->toISOString(),
        ];
    }

    private function masterItem(string $groupId): AdminCultureItem
    {
        $item = AdminCultureItem::query()->where('admin_group_id', $groupId)->with('media')->first();

        if (! $item) {
            throw new ApiException('Konten budaya admin tidak ditemukan.', 'ADMIN_CULTURE_ITEM_NOT_FOUND', 404);
        }

        return $item;
    }

    private function attachedClassItems(string $groupId)
    {
        return ClassCultureItem::query()
            ->where('created_scope', 'admin')
            ->where('admin_group_id', $groupId)
            ->get();
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
            $media = MediaFile::query()->active()->find($data['media_id']);
            if (! $media || $media->purpose !== 'culture_media') {
                throw new ApiException('Media budaya harus menggunakan media culture_media yang aktif.', 'VALIDATION_ERROR', 422);
            }

            $mimeMatches = match ($type) {
                'image' => str_starts_with($media->mime_type, 'image/'),
                'audio' => str_starts_with($media->mime_type, 'audio/'),
                'video' => str_starts_with($media->mime_type, 'video/'),
                'pdf' => $media->mime_type === 'application/pdf',
                default => false,
            };
            if (! $mimeMatches) {
                throw new ApiException('Jenis media tidak sesuai dengan tipe konten.', 'VALIDATION_ERROR', 422);
            }
        }
        if (in_array($type, ['youtube', 'article', 'link'], true) && empty($data['external_url'])) {
            throw new ApiException('URL wajib diisi untuk tipe konten tautan.', 'VALIDATION_ERROR', 422);
        }
    }

    private function validatePublishReadiness(array $data): void
    {
        if (trim((string) ($data['title'] ?? '')) === '') {
            throw new ApiException('Judul wajib diisi sebelum publikasi.', 'VALIDATION_ERROR', 422);
        }

        $this->validateContent($data);
    }

    private function applyStatusTimestamps(AdminCultureItem|ClassCultureItem $item): void
    {
        if ($item->status === 'published') {
            $item->published_at ??= now();
            $item->archived_at = null;
        }

        if ($item->status === 'archived' && $item->archived_at === null) {
            $item->archived_at = now();
        }
    }
}
