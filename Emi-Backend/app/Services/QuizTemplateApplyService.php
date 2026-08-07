<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\ClassQuiz;
use App\Models\QuizTemplate;
use App\Models\SchoolClass;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class QuizTemplateApplyService
{
    public function __construct(private readonly AuditLogService $auditLogService) {}

    public function apply(QuizTemplate $template, array $classIds, User $actor, Request $request, bool $syncExisting = false): array
    {
        if ($template->status !== 'published') {
            throw new ApiException('Template kuis belum published.', 'QUIZ_NOT_PUBLISHED', 409);
        }
        $template->load('questions.options');
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
                    $existing = ClassQuiz::query()->where('class_id', $class->id)->where('source_quiz_template_id', $template->id)->first();
                    if ($existing) {
                        if (! $syncExisting) {
                            $summary['skipped'][] = ['class_id' => $class->id, 'reason' => 'QUIZ_TEMPLATE_ALREADY_APPLIED'];

                            return;
                        }

                        $this->syncExistingQuiz($existing, $template, $actor);
                        $summary['synced'][] = ['class_id' => $class->id, 'class_quiz_id' => $existing->id];
                        $this->auditLogService->record('quiz_template.synced', $existing, $actor, null, ['source_quiz_template_id' => $template->id, 'class_id' => $class->id], [], $request);

                        return;
                    }
                    $quiz = ClassQuiz::query()->create([
                        'class_id' => $class->id,
                        'source_quiz_template_id' => $template->id,
                        'title' => $template->title,
                        'description' => $template->description,
                        'instructions' => $template->instructions,
                        'duration_minutes' => $template->duration_minutes,
                        'max_attempts' => $template->max_attempts,
                        'show_result' => $template->show_result,
                        'status' => 'draft',
                        'created_by' => $actor->id,
                    ]);
                    foreach ($template->questions as $source) {
                        $question = $quiz->questions()->create([
                            'source_quiz_template_question_id' => $source->id,
                            'question_type' => $source->question_type,
                            'question_text' => $source->question_text,
                            'image_media_id' => $source->image_media_id,
                            'correct_answer_text' => $source->correct_answer_text,
                            'use_fuzzy_matching' => $source->use_fuzzy_matching,
                            'fuzzy_threshold' => $source->fuzzy_threshold,
                            'points' => $source->points,
                            'order_number' => $source->order_number,
                            'explanation' => $source->explanation,
                            'created_by' => $actor->id,
                        ]);
                        foreach ($source->options as $option) {
                            $question->options()->create([
                                'source_quiz_template_option_id' => $option->id,
                                'option_text' => $option->option_text,
                                'is_correct' => $option->is_correct,
                                'order_number' => $option->order_number,
                            ]);
                        }
                    }
                    $summary['applied'][] = ['class_id' => $class->id, 'class_quiz_id' => $quiz->id];
                    $this->auditLogService->record('quiz_template.applied', $quiz, $actor, null, ['source_quiz_template_id' => $template->id, 'class_id' => $class->id], [], $request);
                });
            } catch (ApiException $e) {
                $summary['failed'][] = ['class_id' => $classId, 'reason' => $e->errorCode];
            }
        }

        return $summary;
    }

    /**
     * Update an existing ClassQuiz with the latest template changes.
     *
     * - Updates quiz metadata (title, description, instructions, etc.)
     * - For each QuizTemplateQuestion: if a matching QuizQuestion exists
     *   (by source_quiz_template_question_id), update it and its options;
     *   otherwise create a new QuizQuestion with options.
     * - Questions created by the teacher manually (no source_quiz_template_question_id)
     *   are never touched.
     */
    private function syncExistingQuiz(ClassQuiz $quiz, QuizTemplate $template, User $actor): void
    {
        $quiz->forceFill([
            'title' => $template->title,
            'description' => $template->description,
            'instructions' => $template->instructions,
            'duration_minutes' => $template->duration_minutes,
            'max_attempts' => $template->max_attempts,
            'show_result' => $template->show_result,
            'updated_by' => $actor->id,
        ])->save();

        $existingQuestions = $quiz->questions()
            ->whereNotNull('source_quiz_template_question_id')
            ->get()
            ->keyBy('source_quiz_template_question_id');

        foreach ($template->questions as $source) {
            $existingQuestion = $existingQuestions->get($source->id);

            if ($existingQuestion) {
                $existingQuestion->forceFill([
                    'question_type' => $source->question_type,
                    'question_text' => $source->question_text,
                    'image_media_id' => $source->image_media_id,
                    'correct_answer_text' => $source->correct_answer_text,
                    'use_fuzzy_matching' => $source->use_fuzzy_matching,
                    'fuzzy_threshold' => $source->fuzzy_threshold,
                    'points' => $source->points,
                    'order_number' => $source->order_number,
                    'explanation' => $source->explanation,
                    'updated_by' => $actor->id,
                ])->save();

                $existingOptions = $existingQuestion->options()
                    ->whereNotNull('source_quiz_template_option_id')
                    ->get()
                    ->keyBy('source_quiz_template_option_id');

                foreach ($source->options as $option) {
                    $existingOption = $existingOptions->get($option->id);

                    if ($existingOption) {
                        $existingOption->forceFill([
                            'option_text' => $option->option_text,
                            'is_correct' => $option->is_correct,
                            'order_number' => $option->order_number,
                        ])->save();
                    } else {
                        $existingQuestion->options()->create([
                            'source_quiz_template_option_id' => $option->id,
                            'option_text' => $option->option_text,
                            'is_correct' => $option->is_correct,
                            'order_number' => $option->order_number,
                        ]);
                    }
                }
            } else {
                $question = $quiz->questions()->create([
                    'source_quiz_template_question_id' => $source->id,
                    'question_type' => $source->question_type,
                    'question_text' => $source->question_text,
                    'image_media_id' => $source->image_media_id,
                    'correct_answer_text' => $source->correct_answer_text,
                    'use_fuzzy_matching' => $source->use_fuzzy_matching,
                    'fuzzy_threshold' => $source->fuzzy_threshold,
                    'points' => $source->points,
                    'order_number' => $source->order_number,
                    'explanation' => $source->explanation,
                    'created_by' => $actor->id,
                ]);
                foreach ($source->options as $option) {
                    $question->options()->create([
                        'source_quiz_template_option_id' => $option->id,
                        'option_text' => $option->option_text,
                        'is_correct' => $option->is_correct,
                        'order_number' => $option->order_number,
                    ]);
                }
            }
        }
    }
}
