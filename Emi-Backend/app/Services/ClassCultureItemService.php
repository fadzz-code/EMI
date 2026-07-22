<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\ClassCultureItem;
use App\Models\MediaFile;
use App\Models\SchoolClass;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Gate;

class ClassCultureItemService
{
    public function __construct(private readonly AuditLogService $auditLogService) {}

    public function create(SchoolClass $class, array $data, User $actor, Request $request): ClassCultureItem
    {
        $this->assertActiveClass($class);
        $this->validateContent($data, $actor);

        return DB::transaction(function () use ($class, $data, $actor, $request) {
            $item = ClassCultureItem::query()->create([
                'class_id' => $class->id,
                'title' => $data['title'],
                'description' => $data['description'] ?? null,
                'content_type' => $data['content_type'],
                'media_id' => $data['media_id'] ?? null,
                'external_url' => $data['external_url'] ?? null,
                'display_order' => $data['display_order'] ?? 1,
                'status' => $data['status'] ?? 'draft',
                'created_by' => $actor->id,
                'published_at' => ($data['status'] ?? 'draft') === 'published' ? now() : null,
            ]);

            $this->auditLogService->record('class_culture_item.created', $item, $actor, null, $item->only(['title', 'content_type', 'status']), [], $request);

            return $item->refresh()->load('media', 'schoolClass');
        });
    }

    public function update(ClassCultureItem $item, array $data, User $actor, Request $request): ClassCultureItem
    {
        $merged = array_merge($item->toArray(), $data);
        $this->validateContent($merged, $actor);

        return DB::transaction(function () use ($item, $data, $actor, $request) {
            $old = $item->only(['title', 'content_type', 'status']);
            $this->detachAdminGroupForTeacherAction($item, $actor);
            $item->fill(collect($data)->only(['title', 'description', 'content_type', 'media_id', 'external_url', 'display_order', 'status'])->all());
            $item->updated_by = $actor->id;

            if ($item->status === 'published' && $item->published_at === null) {
                $item->published_at = now();
                $item->archived_at = null;
            }

            if ($item->status === 'archived' && $item->archived_at === null) {
                $item->archived_at = now();
            }

            $item->save();

            $this->auditLogService->record('class_culture_item.updated', $item, $actor, $old, $item->only(['title', 'content_type', 'status']), [], $request);

            return $item->refresh()->load('media', 'schoolClass');
        });
    }

    public function publish(ClassCultureItem $item, User $actor, Request $request): ClassCultureItem
    {
        $this->detachAdminGroupForTeacherAction($item, $actor);

        $item->forceFill([
            'status' => 'published',
            'published_at' => $item->published_at ?? now(),
            'archived_at' => null,
            'updated_by' => $actor->id,
        ])->save();

        $this->auditLogService->record('class_culture_item.published', $item, $actor, null, ['status' => 'published'], [], $request);

        return $item->refresh()->load('media', 'schoolClass');
    }

    public function archive(ClassCultureItem $item, User $actor, Request $request): ClassCultureItem
    {
        $this->detachAdminGroupForTeacherAction($item, $actor);

        $item->forceFill([
            'status' => 'archived',
            'archived_at' => now(),
            'updated_by' => $actor->id,
        ])->save();

        $this->auditLogService->record('class_culture_item.archived', $item, $actor, null, ['status' => 'archived'], [], $request);

        return $item->refresh()->load('media', 'schoolClass');
    }

    public function delete(ClassCultureItem $item, User $actor, Request $request): void
    {
        $item->delete();
        $this->auditLogService->record('class_culture_item.deleted', $item, $actor, null, ['deleted_at' => now()->toISOString()], [], $request);
    }

    private function detachAdminGroupForTeacherAction(ClassCultureItem $item, User $actor): void
    {
        if ($actor->role === 'teacher' && $item->created_scope === 'admin' && $item->admin_group_id !== null) {
            $item->admin_group_id = null;
            $item->created_scope = 'teacher';
        }
    }

    private function validateContent(array $data, User $actor): void
    {
        $type = $data['content_type'] ?? null;
        if (in_array($type, ['image', 'audio', 'pdf', 'video'], true) && empty($data['media_id'])) {
            throw new ApiException('Media ID wajib diisi untuk tipe konten file.', 'VALIDATION_ERROR', 422);
        }
        if (in_array($type, ['image', 'audio', 'pdf', 'video'], true) && ! empty($data['media_id'])) {
            $media = MediaFile::query()->find($data['media_id']);
            if (! $media || $media->purpose !== 'culture_media') {
                throw new ApiException('Media budaya harus menggunakan purpose culture_media.', 'VALIDATION_ERROR', 422);
            }
            if (! Gate::forUser($actor)->allows('delete', $media)) {
                throw new ApiException('Media budaya tidak dapat digunakan.', 'MEDIA_FORBIDDEN', 403);
            }
        }
        if (in_array($type, ['youtube', 'article', 'link'], true) && empty($data['external_url'])) {
            throw new ApiException('URL eksternal wajib diisi untuk tipe konten tautan.', 'VALIDATION_ERROR', 422);
        }
    }

    private function assertActiveClass(SchoolClass $class): void
    {
        $class->loadMissing('school');
        if ($class->status !== 'active') {
            throw new ApiException('Kelas tidak aktif.', 'CLASS_INACTIVE', 409);
        }
        if ($class->school?->status !== 'active') {
            throw new ApiException('Sekolah tidak aktif.', 'SCHOOL_INACTIVE', 409);
        }
    }
}
