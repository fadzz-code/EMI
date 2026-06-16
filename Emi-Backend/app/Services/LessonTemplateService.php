<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\LessonTemplate;
use App\Models\ModuleTemplate;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LessonTemplateService
{
    public function __construct(
        private readonly AuditLogService $auditLogService,
        private readonly LessonContentValidationService $contentValidationService,
    ) {}

    public function create(ModuleTemplate $moduleTemplate, array $data, User $actor, Request $request): LessonTemplate
    {
        $this->contentValidationService->validate($data);

        return DB::transaction(function () use ($moduleTemplate, $data, $actor, $request) {
            $lesson = LessonTemplate::query()->create($this->payload($data) + [
                'module_template_id' => $moduleTemplate->id,
                'created_by' => $actor->id,
                'sort_order' => $data['sort_order'] ?? ((int) $moduleTemplate->lessons()->max('sort_order') + 1),
            ]);

            $this->auditLogService->record('lesson_template.created', $lesson, $actor, null, $lesson->only(['title', 'content_type', 'status']), [], $request);

            return $lesson->refresh();
        });
    }

    public function update(LessonTemplate $lesson, array $data, User $actor, Request $request): LessonTemplate
    {
        $merged = array_merge($lesson->only(['content_type', 'content_body', 'media_id', 'external_url']), $data);
        $this->contentValidationService->validate($merged);

        return DB::transaction(function () use ($lesson, $data, $actor, $request) {
            $old = $lesson->only(['title', 'content_type', 'status']);
            $lesson->fill($this->payload($data, false));
            $lesson->updated_by = $actor->id;
            $this->syncStatusTimestamps($lesson);
            $lesson->save();

            $this->auditLogService->record('lesson_template.updated', $lesson, $actor, $old, $lesson->only(['title', 'content_type', 'status']), [], $request);

            return $lesson->refresh();
        });
    }

    public function publish(LessonTemplate $lesson, User $actor, Request $request): LessonTemplate
    {
        $this->contentValidationService->assertValidModel($lesson);
        $lesson->forceFill([
            'status' => 'published',
            'published_at' => $lesson->published_at ?? now(),
            'archived_at' => null,
            'updated_by' => $actor->id,
        ])->save();
        $this->auditLogService->record('lesson_template.published', $lesson, $actor, null, ['status' => 'published'], [], $request);

        return $lesson->refresh();
    }

    public function archive(LessonTemplate $lesson, User $actor, Request $request): LessonTemplate
    {
        $lesson->forceFill(['status' => 'archived', 'archived_at' => now(), 'updated_by' => $actor->id])->save();
        $this->auditLogService->record('lesson_template.archived', $lesson, $actor, null, ['status' => 'archived'], [], $request);

        return $lesson->refresh();
    }

    public function delete(LessonTemplate $lesson, User $actor, Request $request): void
    {
        $lesson->delete();
        $this->auditLogService->record('lesson_template.deleted', $lesson, $actor, null, ['deleted_at' => now()->toISOString()], [], $request);
    }

    public function reorder(ModuleTemplate $moduleTemplate, array $lessonIds, User $actor, Request $request): void
    {
        DB::transaction(function () use ($moduleTemplate, $lessonIds, $actor, $request) {
            $activeIds = $moduleTemplate->lessons()->pluck('id')->all();
            sort($activeIds);
            $given = $lessonIds;
            sort($given);

            if ($activeIds !== $given || count($lessonIds) !== count(array_unique($lessonIds))) {
                throw new ApiException('Urutan materi tidak valid.', 'INVALID_ORDER', 422);
            }

            foreach ($lessonIds as $index => $lessonId) {
                LessonTemplate::query()->whereKey($lessonId)->update(['sort_order' => $index + 1, 'updated_by' => $actor->id]);
            }

            $this->auditLogService->record('lesson_template.reordered', $moduleTemplate, $actor, null, ['lesson_ids' => $lessonIds], [], $request);
        });
    }

    private function payload(array $data, bool $creating = true): array
    {
        $allowed = collect($data)->only(['title', 'description', 'content_type', 'content_body', 'media_id', 'external_url', 'sort_order', 'status'])->all();

        if ($creating) {
            $allowed['status'] = $allowed['status'] ?? 'draft';
        }

        if (($allowed['status'] ?? null) === 'published') {
            $allowed['published_at'] = now();
            $allowed['archived_at'] = null;
        }

        if (($allowed['status'] ?? null) === 'archived') {
            $allowed['archived_at'] = now();
        }

        return $allowed;
    }

    private function syncStatusTimestamps(LessonTemplate $lesson): void
    {
        if ($lesson->status === 'published' && $lesson->published_at === null) {
            $lesson->published_at = now();
            $lesson->archived_at = null;
        }

        if ($lesson->status === 'archived' && $lesson->archived_at === null) {
            $lesson->archived_at = now();
        }
    }
}
