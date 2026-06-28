<?php

namespace App\Services;

use App\Models\CultureTemplate;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CultureTemplateService
{
    public function __construct(private readonly AuditLogService $auditLogService) {}

    public function create(array $data, User $actor, Request $request): CultureTemplate
    {
        return DB::transaction(function () use ($data, $actor, $request) {
            $template = CultureTemplate::query()->create([
                'title' => $data['title'],
                'description' => $data['description'] ?? null,
                'status' => $data['status'] ?? 'draft',
                'created_by' => $actor->id,
                'published_at' => ($data['status'] ?? 'draft') === 'published' ? now() : null,
            ]);

            $this->auditLogService->record('culture_template.created', $template, $actor, null, $template->only(['title', 'status']), [], $request);

            return $template->refresh();
        });
    }

    public function update(CultureTemplate $template, array $data, User $actor, Request $request): CultureTemplate
    {
        if (($data['status'] ?? null) === 'published') {
            return $this->publish($template, $actor, $request);
        }

        return DB::transaction(function () use ($template, $data, $actor, $request) {
            $old = $template->only(['title', 'description', 'status']);
            $template->fill(collect($data)->only(['title', 'description', 'status'])->all());
            $template->updated_by = $actor->id;

            if ($template->status === 'published' && $template->published_at === null) {
                $template->published_at = now();
                $template->archived_at = null;
            }

            if ($template->status === 'archived' && $template->archived_at === null) {
                $template->archived_at = now();
            }

            $template->save();

            $this->auditLogService->record('culture_template.updated', $template, $actor, $old, $template->only(['title', 'description', 'status']), [], $request);

            return $template->refresh();
        });
    }

    public function publish(CultureTemplate $template, User $actor, Request $request): CultureTemplate
    {
        $template->forceFill([
            'status' => 'published',
            'published_at' => $template->published_at ?? now(),
            'archived_at' => null,
            'updated_by' => $actor->id,
        ])->save();

        $this->auditLogService->record('culture_template.published', $template, $actor, null, ['status' => 'published'], [], $request);

        return $template->refresh();
    }

    public function delete(CultureTemplate $template, User $actor, Request $request): void
    {
        $template->delete();
        $this->auditLogService->record('culture_template.deleted', $template, $actor, null, ['deleted_at' => now()->toISOString()], [], $request);
    }
}
