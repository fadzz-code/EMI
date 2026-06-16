<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\ClassLesson;
use App\Models\ClassModule;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ClassLessonService
{
    public function __construct(
        private readonly AuditLogService $auditLogService,
        private readonly LessonContentValidationService $contentValidationService,
        private readonly LearningProgressService $progressService,
    ) {}

    public function create(ClassModule $module, array $data, User $actor, Request $request): ClassLesson
    {
        $this->contentValidationService->validate($data);

        return DB::transaction(function () use ($module, $data, $actor, $request) {
            $lesson = $module->lessons()->create($this->payload($data) + [
                'created_by' => $actor->id,
                'sort_order' => $data['sort_order'] ?? ((int) $module->lessons()->max('sort_order') + 1),
            ]);
            $this->auditLogService->record('class_lesson.created', $lesson, $actor, null, $lesson->only(['title', 'content_type', 'status']), [], $request);
            $this->progressService->recalculateModuleProgressForAllStudents($module);

            return $lesson->refresh();
        });
    }

    public function update(ClassLesson $lesson, array $data, User $actor, Request $request): ClassLesson
    {
        $merged = array_merge($lesson->only(['content_type', 'content_body', 'media_id', 'external_url']), $data);
        $this->contentValidationService->validate($merged);

        return DB::transaction(function () use ($lesson, $data, $actor, $request) {
            $old = $lesson->only(['title', 'content_type', 'status']);
            $lesson->fill($this->payload($data, false));
            $lesson->updated_by = $actor->id;
            $this->syncStatus($lesson);
            $lesson->save();
            $this->auditLogService->record('class_lesson.updated', $lesson, $actor, $old, $lesson->only(['title', 'content_type', 'status']), [], $request);
            $this->progressService->recalculateModuleProgressForAllStudents($lesson->classModule);

            return $lesson->refresh();
        });
    }

    public function publish(ClassLesson $lesson, User $actor, Request $request): ClassLesson
    {
        $this->contentValidationService->assertValidModel($lesson);
        $lesson->forceFill(['status' => 'published', 'published_at' => $lesson->published_at ?? now(), 'archived_at' => null, 'updated_by' => $actor->id])->save();
        $this->auditLogService->record('class_lesson.published', $lesson, $actor, null, ['status' => 'published'], [], $request);
        $this->progressService->recalculateModuleProgressForAllStudents($lesson->classModule);

        return $lesson->refresh();
    }

    public function archive(ClassLesson $lesson, User $actor, Request $request): ClassLesson
    {
        $lesson->forceFill(['status' => 'archived', 'archived_at' => now(), 'updated_by' => $actor->id])->save();
        $this->auditLogService->record('class_lesson.archived', $lesson, $actor, null, ['status' => 'archived'], [], $request);
        $this->progressService->recalculateModuleProgressForAllStudents($lesson->classModule);

        return $lesson->refresh();
    }

    public function delete(ClassLesson $lesson, User $actor, Request $request): void
    {
        if ($lesson->status !== 'draft' || $lesson->progress()->exists()) {
            throw new ApiException('Materi memiliki progress dan harus diarsipkan.', 'LESSON_HAS_PROGRESS', 409);
        }

        $module = $lesson->classModule;
        $lesson->delete();
        $this->auditLogService->record('class_lesson.deleted', $lesson, $actor, null, ['deleted_at' => now()->toISOString()], [], $request);
        $this->progressService->recalculateModuleProgressForAllStudents($module);
    }

    public function reorder(ClassModule $module, array $lessonIds, User $actor, Request $request): void
    {
        DB::transaction(function () use ($module, $lessonIds, $actor, $request) {
            $activeIds = $module->lessons()->pluck('id')->all();
            sort($activeIds);
            $given = $lessonIds;
            sort($given);

            if ($activeIds !== $given || count($lessonIds) !== count(array_unique($lessonIds))) {
                throw new ApiException('Urutan materi tidak valid.', 'INVALID_ORDER', 422);
            }

            foreach ($lessonIds as $index => $lessonId) {
                ClassLesson::query()->whereKey($lessonId)->update(['sort_order' => $index + 1, 'updated_by' => $actor->id]);
            }

            $this->auditLogService->record('class_lesson.reordered', $module, $actor, null, ['lesson_ids' => $lessonIds], [], $request);
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

    private function syncStatus(ClassLesson $lesson): void
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
