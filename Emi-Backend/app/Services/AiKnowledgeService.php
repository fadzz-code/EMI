<?php

namespace App\Services;

use App\Models\AiKnowledgeItem;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AiKnowledgeService
{
    public function __construct(
        private readonly AuditLogService $auditLogService,
        private readonly AiKnowledgeChunkingService $chunkingService,
    ) {}

    public function create(array $data, User $actor, Request $request): AiKnowledgeItem
    {
        return DB::transaction(function () use ($data, $actor, $request) {
            $item = AiKnowledgeItem::query()->create([
                'title' => $data['title'],
                'category' => $data['category'] ?? null,
                'content' => $data['content'],
                'source_type' => $data['source_type'],
                'source_url' => $data['source_url'] ?? null,
                'status' => $data['status'] ?? 'draft',
                'created_by' => $actor->id,
            ]);

            $this->chunkingService->rebuild($item);
            $item->refresh();
            $this->ensureReadyWhenPublished($item);
            $this->auditLogService->record('ai_knowledge_item.created', $item, $actor, null, $item->only(['title', 'category', 'source_type', 'status']), [], $request);

            return $item->refresh();
        });
    }

    public function update(AiKnowledgeItem $item, array $data, User $actor, Request $request): AiKnowledgeItem
    {
        return DB::transaction(function () use ($item, $data, $actor, $request) {
            $old = $item->only(['title', 'category', 'content', 'source_type', 'source_url', 'status']);
            $item->fill(collect($data)->only(['title', 'category', 'content', 'source_type', 'source_url', 'status'])->all());
            $item->updated_by = $actor->id;
            $item->save();
            $this->chunkingService->rebuild($item);
            $item->refresh();
            $this->ensureReadyWhenPublished($item);

            $this->auditLogService->record('ai_knowledge_item.updated', $item, $actor, $old, $item->only(['title', 'category', 'content', 'source_type', 'source_url', 'status']), [], $request);

            return $item->refresh();
        });
    }

    public function publish(AiKnowledgeItem $item, User $actor, Request $request): AiKnowledgeItem
    {
        return $this->setStatus($item, 'published', $actor, $request, 'ai_knowledge_item.published');
    }

    public function archive(AiKnowledgeItem $item, User $actor, Request $request): AiKnowledgeItem
    {
        return $this->setStatus($item, 'archived', $actor, $request, 'ai_knowledge_item.archived');
    }

    public function delete(AiKnowledgeItem $item, User $actor, Request $request): void
    {
        $item->delete();
        $this->auditLogService->record('ai_knowledge_item.deleted', $item, $actor, null, ['deleted_at' => now()->toISOString()], [], $request);
    }

    public function retryProcessing(AiKnowledgeItem $item, User $actor, Request $request): AiKnowledgeItem
    {
        abort_unless(in_array($item->source_type, ['pdf', 'link'], true), 422, 'Sumber ini tidak dapat diproses ulang.');
        abort_if($item->processingStatus() === 'ready', 409, 'Pengetahuan sudah siap digunakan.');

        $this->chunkingService->rebuild($item);
        $this->auditLogService->record('ai_knowledge_item.processing_retried', $item, $actor, null, ['processing_status' => $item->processingStatus()], [], $request);

        return $item->refresh();
    }

    private function ensureReadyWhenPublished(AiKnowledgeItem $item, ?string $status = null): void
    {
        if (($status ?? $item->status) === 'published' && ! $item->isReadyForPublication()) {
            abort(409, 'Sumber pengetahuan belum siap digunakan.');
        }
    }

    private function setStatus(AiKnowledgeItem $item, string $status, User $actor, Request $request, string $action): AiKnowledgeItem
    {
        if ($status === 'published') {
            if ($item->source_type === 'manual' || ($item->sourcePages()->doesntExist() && ! str_starts_with(trim((string) $item->content), 'Dokumen PDF telah diproses'))) {
                $this->chunkingService->ensureChunks($item);
                $item->refresh();
            }
            $this->ensureReadyWhenPublished($item, $status);
        }

        $item->forceFill([
            'status' => $status,
            'updated_by' => $actor->id,
        ])->save();

        $this->auditLogService->record($action, $item, $actor, null, ['status' => $status], [], $request);

        return $item->refresh();
    }
}
