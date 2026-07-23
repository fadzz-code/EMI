<?php

namespace App\Services;

use App\Models\CultureTemplate;
use App\Models\CultureTemplateItem;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CultureTemplateItemService
{
    public function __construct(
        private readonly AuditLogService $auditLogService,
        private readonly CultureContentValidator $contentValidator,
        private readonly CultureMediaCleanupService $mediaCleanupService,
    ) {}

    public function create(CultureTemplate $template, array $data, User $actor, Request $request): CultureTemplateItem
    {
        $data = $this->contentValidator->normalize($data);
        $this->contentValidator->validate($data, $actor);

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
        $data = $this->contentValidator->normalize($data, $item->content_type);
        $merged = array_merge($item->toArray(), $data);
        $this->contentValidator->validate($merged, $actor);

        return DB::transaction(function () use ($item, $data, $actor, $request) {
            $old = $item->only(['title', 'content_type', 'status']);
            $oldMediaId = $item->media_id;
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
            if ($oldMediaId !== $item->media_id) {
                $this->mediaCleanupService->afterCommit([$oldMediaId], $actor, $request);
            }

            return $item->refresh()->load('media');
        });
    }

    public function delete(CultureTemplateItem $item, User $actor, Request $request): void
    {
        DB::transaction(function () use ($item, $actor, $request) {
            $mediaIds = [$item->media_id, $item->thumbnail_media_id];
            $item->delete();
            $this->auditLogService->record('culture_template_item.deleted', $item, $actor, null, ['deleted_at' => now()->toISOString()], [], $request);
            $this->mediaCleanupService->afterCommit($mediaIds, $actor, $request);
        });
    }
}
