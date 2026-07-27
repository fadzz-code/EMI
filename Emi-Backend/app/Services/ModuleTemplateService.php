<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\ModuleTemplate;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ModuleTemplateService
{
    public function __construct(
        private readonly AuditLogService $auditLogService,
        private readonly LessonContentValidationService $contentValidationService,
    ) {}

    public function create(array $data, User $actor, Request $request): ModuleTemplate
    {
        if (($data['status'] ?? 'draft') === 'published') {
            throw new ApiException('Template modul harus memiliki minimal satu materi published.', 'MODULE_HAS_NO_PUBLISHED_LESSONS', 409);
        }

        return DB::transaction(function () use ($data, $actor, $request) {
            $template = ModuleTemplate::query()->create([
                'title' => $data['title'],
                'description' => $data['description'] ?? null,
                'status' => $data['status'] ?? 'draft',
                'created_by' => $actor->id,
                'published_at' => ($data['status'] ?? 'draft') === 'published' ? now() : null,
            ]);

            $this->auditLogService->record('module_template.created', $template, $actor, null, $template->only(['title', 'status']), [], $request);

            return $template->refresh();
        });
    }

    public function update(ModuleTemplate $template, array $data, User $actor, Request $request): ModuleTemplate
    {
        $requestedStatus = $data['status'] ?? $template->status;
        $isPublishTransition = $requestedStatus === 'published' && $template->status !== 'published';

        if ($isPublishTransition) {
            $template->fill(collect($data)->only(['title', 'description'])->all());

            return $this->publish($template, $actor, $request);
        }

        return DB::transaction(function () use ($template, $data, $actor, $request) {
            $old = $template->only(['title', 'description', 'status']);
            $template->fill(collect($data)->only(['title', 'description', 'status'])->all());
            $template->updated_by = $actor->id;
            $this->syncStatusTimestamps($template);
            $template->save();

            $this->auditLogService->record('module_template.updated', $template, $actor, $old, $template->only(['title', 'description', 'status']), [], $request);

            return $template->refresh();
        });
    }

    public function publish(ModuleTemplate $template, User $actor, Request $request): ModuleTemplate
    {
        if ($template->status === 'archived') {
            throw new ApiException('Template modul archived tidak dapat dipublish.', 'INVALID_LESSON_CONTENT', 409);
        }

        $template->load('lessons.media');
        $publishedLessons = $template->lessons->where('status', 'published');

        if ($publishedLessons->isEmpty()) {
            throw new ApiException('Template modul harus memiliki minimal satu materi published.', 'MODULE_HAS_NO_PUBLISHED_LESSONS', 409);
        }

        foreach ($publishedLessons as $lesson) {
            $this->contentValidationService->assertValidModel($lesson);
        }

        $template->forceFill([
            'status' => 'published',
            'published_at' => $template->published_at ?? now(),
            'archived_at' => null,
            'updated_by' => $actor->id,
        ])->save();

        $this->auditLogService->record('module_template.published', $template, $actor, null, ['status' => 'published'], [], $request);

        return $template->refresh();
    }

    public function archive(ModuleTemplate $template, User $actor, Request $request): ModuleTemplate
    {
        $template->forceFill([
            'status' => 'archived',
            'archived_at' => now(),
            'updated_by' => $actor->id,
        ])->save();

        $this->auditLogService->record('module_template.archived', $template, $actor, null, ['status' => 'archived'], [], $request);

        return $template->refresh();
    }

    public function delete(ModuleTemplate $template, User $actor, Request $request): void
    {
        $template->delete();
        $this->auditLogService->record('module_template.deleted', $template, $actor, null, ['deleted_at' => now()->toISOString()], [], $request);
    }

    private function syncStatusTimestamps(ModuleTemplate $template): void
    {
        if ($template->status === 'published' && $template->published_at === null) {
            $template->published_at = now();
            $template->archived_at = null;
        }

        if ($template->status === 'archived' && $template->archived_at === null) {
            $template->archived_at = now();
        }
    }
}
