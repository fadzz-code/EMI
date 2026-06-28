<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\CultureTemplate;
use App\Models\CultureTemplateItem;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CultureTemplateItemService
{
    public function __construct(private readonly AuditLogService $auditLogService) {}

    public function create(CultureTemplate $template, array $data, User $actor, Request $request): CultureTemplateItem
    {
        $this->validateContent($data);

        return DB::transaction(function () use ($template, $data, $actor, $request) {
            $item = $template->items()->create([
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

            $this->auditLogService->record('culture_template_item.created', $item, $actor, null, $item->only(['title', 'content_type', 'status']), [], $request);

            return $item->refresh()->load('media');
        });
    }

    public function update(CultureTemplateItem $item, array $data, User $actor, Request $request): CultureTemplateItem
    {
        $merged = array_merge($item->toArray(), $data);
        $this->validateContent($merged);

        return DB::transaction(function () use ($item, $data, $actor, $request) {
            $old = $item->only(['title', 'content_type', 'status']);
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

            $this->auditLogService->record('culture_template_item.updated', $item, $actor, $old, $item->only(['title', 'content_type', 'status']), [], $request);

            return $item->refresh()->load('media');
        });
    }

    public function delete(CultureTemplateItem $item, User $actor, Request $request): void
    {
        $item->delete();
        $this->auditLogService->record('culture_template_item.deleted', $item, $actor, null, ['deleted_at' => now()->toISOString()], [], $request);
    }

    private function validateContent(array $data): void
    {
        $type = $data['content_type'] ?? null;
        if (in_array($type, ['image', 'audio', 'pdf', 'video'], true) && empty($data['media_id'])) {
            throw new ApiException('Media ID wajib diisi untuk tipe konten file.', 'VALIDATION_ERROR', 422);
        }
        if (in_array($type, ['youtube', 'article', 'link'], true) && empty($data['external_url'])) {
            throw new ApiException('URL eksternal wajib diisi untuk tipe konten tautan.', 'VALIDATION_ERROR', 422);
        }
    }
}
