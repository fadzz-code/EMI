<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\ClassModule;
use App\Models\SchoolClass;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ClassModuleService
{
    public function __construct(
        private readonly AuditLogService $auditLogService,
        private readonly LessonContentValidationService $contentValidationService,
    ) {}

    public function create(SchoolClass $class, array $data, User $actor, Request $request): ClassModule
    {
        $this->assertActiveClass($class);

        return DB::transaction(function () use ($class, $data, $actor, $request) {
            $module = ClassModule::query()->create([
                'class_id' => $class->id,
                'title' => $data['title'],
                'description' => $data['description'] ?? null,
                'status' => $data['status'] ?? 'draft',
                'sort_order' => $data['sort_order'] ?? ((int) $class->classModules()->max('sort_order') + 1),
                'created_by' => $actor->id,
                'published_at' => ($data['status'] ?? 'draft') === 'published' ? now() : null,
            ]);

            $this->auditLogService->record('class_module.created', $module, $actor, null, $module->only(['class_id', 'title', 'status']), [], $request);

            return $module->refresh();
        });
    }

    public function update(ClassModule $module, array $data, User $actor, Request $request): ClassModule
    {
        return DB::transaction(function () use ($module, $data, $actor, $request) {
            $old = $module->only(['title', 'description', 'status']);
            $module->fill(collect($data)->only(['title', 'description', 'status', 'sort_order'])->all());
            $module->updated_by = $actor->id;
            $this->syncStatus($module);
            $module->save();
            $this->auditLogService->record('class_module.updated', $module, $actor, $old, $module->only(['title', 'description', 'status']), [], $request);

            return $module->refresh();
        });
    }

    public function publish(ClassModule $module, User $actor, Request $request): ClassModule
    {
        $module->load('schoolClass.school', 'lessons.media');
        $this->assertActiveClass($module->schoolClass);
        $publishedLessons = $module->lessons->where('status', 'published');

        if ($publishedLessons->isEmpty()) {
            throw new ApiException('Modul kelas harus memiliki minimal satu materi published.', 'MODULE_HAS_NO_PUBLISHED_LESSONS', 409);
        }

        foreach ($publishedLessons as $lesson) {
            $this->contentValidationService->assertValidModel($lesson);
        }

        $module->forceFill(['status' => 'published', 'published_at' => $module->published_at ?? now(), 'archived_at' => null, 'updated_by' => $actor->id])->save();
        $this->auditLogService->record('class_module.published', $module, $actor, null, ['status' => 'published'], [], $request);

        return $module->refresh();
    }

    public function archive(ClassModule $module, User $actor, Request $request): ClassModule
    {
        $module->forceFill(['status' => 'archived', 'archived_at' => now(), 'updated_by' => $actor->id])->save();
        $this->auditLogService->record('class_module.archived', $module, $actor, null, ['status' => 'archived'], [], $request);

        return $module->refresh();
    }

    public function delete(ClassModule $module, User $actor, Request $request): void
    {
        if ($module->status !== 'draft' || $module->progress()->exists() || $module->lessons()->whereHas('progress')->exists()) {
            throw new ApiException('Modul memiliki progress dan harus diarsipkan.', 'MODULE_HAS_PROGRESS', 409);
        }

        $module->delete();
        $this->auditLogService->record('class_module.deleted', $module, $actor, null, ['deleted_at' => now()->toISOString()], [], $request);
    }

    public function reorder(SchoolClass $class, array $moduleIds, User $actor, Request $request): void
    {
        DB::transaction(function () use ($class, $moduleIds, $actor, $request) {
            $activeIds = $class->classModules()->pluck('id')->all();
            sort($activeIds);
            $given = $moduleIds;
            sort($given);

            if ($activeIds !== $given || count($moduleIds) !== count(array_unique($moduleIds))) {
                throw new ApiException('Urutan modul tidak valid.', 'INVALID_ORDER', 422);
            }

            foreach ($moduleIds as $index => $moduleId) {
                ClassModule::query()->whereKey($moduleId)->update(['sort_order' => $index + 1, 'updated_by' => $actor->id]);
            }

            $this->auditLogService->record('class_module.reordered', $class, $actor, null, ['module_ids' => $moduleIds], [], $request);
        });
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

    private function syncStatus(ClassModule $module): void
    {
        if ($module->status === 'published' && $module->published_at === null) {
            $module->published_at = now();
            $module->archived_at = null;
        }

        if ($module->status === 'archived' && $module->archived_at === null) {
            $module->archived_at = now();
        }
    }
}
