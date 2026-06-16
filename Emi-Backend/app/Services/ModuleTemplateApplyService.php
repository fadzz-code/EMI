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

    public function apply(ModuleTemplate $template, array $classIds, User $actor, Request $request): array
    {
        $template->load('lessons');

        if ($template->status !== 'published') {
            throw new ApiException('Template modul belum published.', 'MODULE_TEMPLATE_NOT_PUBLISHED', 409);
        }

        $summary = ['applied' => [], 'skipped' => [], 'failed' => []];

        foreach (array_values(array_unique($classIds)) as $classId) {
            try {
                DB::transaction(function () use ($template, $classId, $actor, $request, &$summary) {
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
                        $summary['skipped'][] = ['class_id' => $class->id, 'reason' => 'MODULE_TEMPLATE_ALREADY_APPLIED'];

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
}
