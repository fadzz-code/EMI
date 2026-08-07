<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\ClassModule;
use App\Models\ModuleTemplate;
use App\Models\SchoolClass;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ModuleTemplateApplyService
{
    public function __construct(private readonly AuditLogService $auditLogService) {}

    public function apply(ModuleTemplate $template, array $classIds, User $actor, Request $request, bool $syncExisting = false): array
    {
        $template->load('lessons');

        if ($template->status !== 'published') {
            throw new ApiException('Template modul belum published.', 'MODULE_TEMPLATE_NOT_PUBLISHED', 409);
        }

        $summary = ['applied' => [], 'synced' => [], 'skipped' => [], 'failed' => []];

        foreach (array_values(array_unique($classIds)) as $classId) {
            try {
                DB::transaction(function () use ($template, $classId, $actor, $request, $syncExisting, &$summary) {
                    $class = SchoolClass::query()->with('school')->lockForUpdate()->findOrFail($classId);

                    if ($class->status !== 'active') {
                        throw new ApiException('Kelas tidak aktif.', 'CLASS_INACTIVE', 409);
                    }

                    if ($class->school?->status !== 'active') {
                        throw new ApiException('Sekolah tidak aktif.', 'SCHOOL_INACTIVE', 409);
                    }

                    $existing = ClassModule::query()
                        ->where('class_id', $class->id)
                        ->where('source_module_template_id', $template->id)
                        ->first();

                    if ($existing) {
                        if (! $syncExisting) {
                            $summary['skipped'][] = ['class_id' => $class->id, 'reason' => 'MODULE_TEMPLATE_ALREADY_APPLIED'];

                            return;
                        }

                        $this->syncExistingModule($existing, $template, $actor);
                        $summary['synced'][] = ['class_id' => $class->id, 'class_module_id' => $existing->id];
                        $this->auditLogService->record('module_template.synced', $existing, $actor, null, [
                            'source_module_template_id' => $template->id,
                            'class_id' => $class->id,
                        ], [], $request);

                        return;
                    }

                    $sortOrder = ((int) ClassModule::query()->where('class_id', $class->id)->max('sort_order')) + 1;
                    $module = ClassModule::query()->create([
                        'class_id' => $class->id,
                        'source_module_template_id' => $template->id,
                        'title' => $template->title,
                        'description' => $template->description,
                        'status' => 'draft',
                        'sort_order' => $sortOrder,
                        'created_by' => $actor->id,
                    ]);

                    foreach ($template->lessons->where('status', 'published') as $lesson) {
                        $module->lessons()->create([
                            'source_lesson_template_id' => $lesson->id,
                            'title' => $lesson->title,
                            'description' => $lesson->description,
                            'content_type' => $lesson->content_type,
                            'content_body' => $lesson->content_body,
                            'media_id' => $lesson->media_id,
                            'external_url' => $lesson->external_url,
                            'sort_order' => $lesson->sort_order,
                            'status' => 'published',
                            'published_at' => now(),
                            'created_by' => $actor->id,
                        ]);
                    }

                    $summary['applied'][] = ['class_id' => $class->id, 'class_module_id' => $module->id];
                    $this->auditLogService->record('module_template.applied', $module, $actor, null, [
                        'source_module_template_id' => $template->id,
                        'class_id' => $class->id,
                    ], [], $request);
                });
            } catch (ApiException $e) {
                $summary['failed'][] = ['class_id' => $classId, 'reason' => $e->errorCode];
            }
        }

        return $summary;
    }

    /**
     * Update an existing ClassModule with the latest template changes.
     *
     * - Updates module title and description (only if the teacher hasn't
     *   customised them — we always sync because the admin template is the
     *   source of truth for structural metadata).
     * - For each published LessonTemplate: if a matching ClassLesson exists
     *   (by source_lesson_template_id), update its content; otherwise create
     *   a new ClassLesson.
     * - ClassLessons created by the teacher manually (no source_lesson_template_id)
     *   are never touched.
     */
    private function syncExistingModule(ClassModule $module, ModuleTemplate $template, User $actor): void
    {
        $module->forceFill([
            'title' => $template->title,
            'description' => $template->description,
            'updated_by' => $actor->id,
        ])->save();

        $existingLessons = $module->lessons()
            ->whereNotNull('source_lesson_template_id')
            ->get()
            ->keyBy('source_lesson_template_id');

        foreach ($template->lessons->where('status', 'published') as $lesson) {
            $existingLesson = $existingLessons->get($lesson->id);

            if ($existingLesson) {
                $existingLesson->forceFill([
                    'title' => $lesson->title,
                    'description' => $lesson->description,
                    'content_type' => $lesson->content_type,
                    'content_body' => $lesson->content_body,
                    'media_id' => $lesson->media_id,
                    'external_url' => $lesson->external_url,
                    'sort_order' => $lesson->sort_order,
                    'updated_by' => $actor->id,
                ])->save();
            } else {
                $module->lessons()->create([
                    'source_lesson_template_id' => $lesson->id,
                    'title' => $lesson->title,
                    'description' => $lesson->description,
                    'content_type' => $lesson->content_type,
                    'content_body' => $lesson->content_body,
                    'media_id' => $lesson->media_id,
                    'external_url' => $lesson->external_url,
                    'sort_order' => $lesson->sort_order,
                    'status' => 'published',
                    'published_at' => now(),
                    'created_by' => $actor->id,
                ]);
            }
        }
    }
}
