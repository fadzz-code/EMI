<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\ClassLesson;
use App\Models\ClassModule;
use App\Models\LessonProgress;
use App\Models\ModuleProgress;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class LearningProgressService
{
    public function __construct(private readonly LearningAccessService $accessService) {}

    public function startModule(User $student, ClassModule $module): ModuleProgress
    {
        if (! $this->accessService->studentCanAccessModule($student, $module)) {
            throw new ApiException('Modul tidak dapat diakses.', 'MODULE_NOT_ACCESSIBLE', 404);
        }

        return DB::transaction(function () use ($student, $module) {
            $progress = ModuleProgress::query()->firstOrCreate([
                'student_id' => $student->id,
                'class_module_id' => $module->id,
            ], [
                'status' => 'in_progress',
                'progress_percent' => 0,
                'started_at' => now(),
            ]);

            if ($progress->status === 'not_started') {
                $progress->forceFill([
                    'status' => 'in_progress',
                    'started_at' => $progress->started_at ?? now(),
                ])->save();
            }

            return $this->recalculateModuleProgress($student, $module);
        });
    }

    public function updateLessonProgress(User $student, ClassLesson $lesson, string $status, ?int $percent = null): LessonProgress
    {
        if (! $this->accessService->studentCanAccessLesson($student, $lesson)) {
            throw new ApiException('Materi tidak dapat diakses.', 'LESSON_NOT_ACCESSIBLE', 404);
        }

        [$status, $percent] = $this->normalizeProgress($status, $percent);

        return DB::transaction(function () use ($student, $lesson, $status, $percent) {
            $progress = LessonProgress::query()->firstOrNew([
                'student_id' => $student->id,
                'class_lesson_id' => $lesson->id,
            ]);

            $progress->fill([
                'status' => $status,
                'progress_percent' => $percent,
                'started_at' => $progress->started_at ?? ($status !== 'not_started' ? now() : null),
                'completed_at' => $status === 'completed' ? ($progress->completed_at ?? now()) : null,
                'last_accessed_at' => now(),
            ]);
            $progress->save();
            $this->recalculateModuleProgress($student, $lesson->classModule);

            return $progress->refresh();
        });
    }

    public function recalculateModuleProgress(User $student, ClassModule $module): ModuleProgress
    {
        $module->loadMissing('lessons');
        $publishedLessonIds = $module->lessons()->where('status', 'published')->pluck('id');
        $total = $publishedLessonIds->count();
        $completed = $total > 0
            ? LessonProgress::query()
                ->where('student_id', $student->id)
                ->whereIn('class_lesson_id', $publishedLessonIds)
                ->where('status', 'completed')
                ->count()
            : 0;

        $percent = $total > 0 ? (int) floor(($completed / $total) * 100) : 0;
        $status = match (true) {
            $total === 0 || $percent === 0 => 'not_started',
            $completed === $total => 'completed',
            default => 'in_progress',
        };

        return ModuleProgress::query()->updateOrCreate([
            'student_id' => $student->id,
            'class_module_id' => $module->id,
        ], [
            'status' => $status,
            'progress_percent' => $percent,
            'completed_lessons' => $completed,
            'total_lessons' => $total,
            'started_at' => $status !== 'not_started'
                ? (ModuleProgress::query()->where('student_id', $student->id)->where('class_module_id', $module->id)->value('started_at') ?? now())
                : null,
            'completed_at' => $status === 'completed' ? now() : null,
            'last_calculated_at' => now(),
        ]);
    }

    public function recalculateModuleProgressForAllStudents(ClassModule $module): void
    {
        ModuleProgress::query()
            ->where('class_module_id', $module->id)
            ->with('student')
            ->get()
            ->each(fn (ModuleProgress $progress) => $this->recalculateModuleProgress($progress->student, $module));
    }

    private function normalizeProgress(string $status, ?int $percent): array
    {
        if ($status === 'completed') {
            return ['completed', 100];
        }

        if ($status === 'not_started') {
            return ['not_started', 0];
        }

        if ($status === 'in_progress' && $percent !== null && $percent >= 1 && $percent <= 99) {
            return ['in_progress', $percent];
        }

        throw new ApiException('Progress materi tidak valid.', 'INVALID_PROGRESS', 422);
    }
}
