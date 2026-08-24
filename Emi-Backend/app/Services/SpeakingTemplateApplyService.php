<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\SchoolClass;
use App\Models\SpeakingExercise;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SpeakingTemplateApplyService
{
    public function __construct(private readonly AuditLogService $auditLogService) {}

    public function apply(SpeakingExercise $template, array $classIds, User $actor, Request $request, bool $syncExisting = false): array
    {
        if ($template->status !== 'published') {
            throw new ApiException('Template speaking belum published.', 'SPEAKING_TEMPLATE_NOT_PUBLISHED', 409);
        }

        if ($template->classroom_id !== null) {
            throw new ApiException('Hanya template speaking global yang dapat diterapkan ke kelas.', 'SPEAKING_TEMPLATE_NOT_GLOBAL', 409);
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

                    $existing = SpeakingExercise::query()
                        ->where('classroom_id', $class->id)
                        ->where('source_speaking_exercise_id', $template->id)
                        ->first();

                    if ($existing) {
                        if (! $syncExisting) {
                            $summary['skipped'][] = ['class_id' => $class->id, 'reason' => 'SPEAKING_TEMPLATE_ALREADY_APPLIED'];

                            return;
                        }

                        $this->syncExistingExercise($existing, $template, $actor);
                        $summary['synced'][] = ['class_id' => $class->id, 'speaking_exercise_id' => $existing->id];
                        $this->auditLogService->record('speaking_template.synced', $existing, $actor, null, [
                            'source_speaking_exercise_id' => $template->id,
                            'class_id' => $class->id,
                        ], [], $request);

                        return;
                    }

                    $exercise = SpeakingExercise::query()->create([
                        'classroom_id' => $class->id,
                        'source_speaking_exercise_id' => $template->id,
                        'title' => $template->title,
                        'prompt_text' => $template->prompt_text,
                        'target_text' => $template->target_text,
                        'target_translation' => $template->target_translation,
                        'reference_audio_media_id' => $template->reference_audio_media_id,
                        'language_code' => $template->language_code ?? 'mekongga',
                        'difficulty' => $template->difficulty,
                        'status' => 'draft',
                        'created_by_id' => $actor->id,
                        'metadata' => $template->metadata,
                    ]);

                    $summary['applied'][] = ['class_id' => $class->id, 'speaking_exercise_id' => $exercise->id];
                    $this->auditLogService->record('speaking_template.applied', $exercise, $actor, null, [
                        'source_speaking_exercise_id' => $template->id,
                        'class_id' => $class->id,
                    ], [], $request);
                });
            } catch (ApiException $e) {
                $summary['failed'][] = ['class_id' => $classId, 'reason' => $e->errorCode];
            }
        }

        return $summary;
    }

    private function syncExistingExercise(SpeakingExercise $exercise, SpeakingExercise $template, User $actor): void
    {
        $exercise->forceFill([
            'title' => $template->title,
            'prompt_text' => $template->prompt_text,
            'target_text' => $template->target_text,
            'target_translation' => $template->target_translation,
            'reference_audio_media_id' => $template->reference_audio_media_id,
            'language_code' => $template->language_code ?? 'mekongga',
            'difficulty' => $template->difficulty,
            'metadata' => $template->metadata,
            'created_by_id' => $actor->id,
        ])->save();
    }
}
