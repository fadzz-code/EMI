<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\QuizTemplate;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class QuizTemplateService
{
    public function __construct(private readonly AuditLogService $auditLogService, private readonly QuizQuestionValidationService $questionValidationService) {}

    public function create(array $data, User $actor, Request $request): QuizTemplate
    {
        $this->validateLimits($data);
        if (($data['status'] ?? 'draft') === 'published') {
            throw new ApiException('Template kuis harus memiliki soal.', 'QUIZ_HAS_NO_QUESTIONS', 409);
        }

        return DB::transaction(function () use ($data, $actor, $request) {
            $template = QuizTemplate::query()->create([
                'title' => $data['title'],
                'description' => $data['description'] ?? null,
                'instructions' => $data['instructions'] ?? null,
                'duration_minutes' => $data['duration_minutes'],
                'max_attempts' => $data['max_attempts'],
                'show_result' => $data['show_result'] ?? true,
                'status' => $data['status'] ?? 'draft',
                'created_by' => $actor->id,
            ]);
            $this->auditLogService->record('quiz_template.created', $template, $actor, null, $template->only(['title', 'status']), [], $request);

            return $template->refresh();
        });
    }

    public function update(QuizTemplate $template, array $data, User $actor, Request $request): QuizTemplate
    {
        if ($template->status === 'published') {
            throw new ApiException('Konten template kuis published terkunci.', 'QUIZ_CONTENT_LOCKED', 409);
        }
        if (($data['status'] ?? null) === 'published') {
            return $this->publish($template, $actor, $request);
        }
        $this->validateLimits(array_merge($template->only(['duration_minutes', 'max_attempts']), $data));

        return DB::transaction(function () use ($template, $data, $actor, $request) {
            $old = $template->only(['title', 'status']);
            $template->fill(collect($data)->only(['title', 'description', 'instructions', 'duration_minutes', 'max_attempts', 'show_result', 'status'])->all());
            $template->updated_by = $actor->id;
            if ($template->status === 'archived') {
                $template->archived_at = now();
            } elseif ($template->status === 'draft') {
                $template->archived_at = null;
            }
            $template->save();
            $this->auditLogService->record('quiz_template.updated', $template, $actor, $old, $template->only(['title', 'status']), [], $request);

            return $template->refresh();
        });
    }

    public function publish(QuizTemplate $template, User $actor, Request $request): QuizTemplate
    {
        $template->load('questions.options', 'questions.imageMedia');
        if ($template->questions->isEmpty()) {
            throw new ApiException('Template kuis harus memiliki soal.', 'QUIZ_HAS_NO_QUESTIONS', 409);
        }
        foreach ($template->questions as $question) {
            $this->questionValidationService->validate($question->toArray() + ['options' => $question->options->map(fn ($option) => $option->only(['option_text', 'is_correct', 'order_number']))->all()]);
        }
        $template->forceFill(['status' => 'published', 'published_at' => $template->published_at ?? now(), 'archived_at' => null, 'updated_by' => $actor->id])->save();
        $this->auditLogService->record('quiz_template.published', $template, $actor, null, ['status' => 'published'], [], $request);

        return $template->refresh();
    }

    public function archive(QuizTemplate $template, User $actor, Request $request): QuizTemplate
    {
        $template->forceFill(['status' => 'archived', 'archived_at' => now(), 'updated_by' => $actor->id])->save();
        $this->auditLogService->record('quiz_template.archived', $template, $actor, null, ['status' => 'archived'], [], $request);

        return $template->refresh();
    }

    public function delete(QuizTemplate $template, User $actor, Request $request): void
    {
        $template->delete();
        $this->auditLogService->record('quiz_template.deleted', $template, $actor, null, ['deleted_at' => now()->toISOString()], [], $request);
    }

    private function validateLimits(array $data): void
    {
        if (($data['duration_minutes'] ?? 0) < 1 || ($data['duration_minutes'] ?? 0) > (int) config('quiz.max_duration_minutes')) {
            throw new ApiException('Durasi kuis tidak valid.', 'VALIDATION_ERROR', 422);
        }
        if (($data['max_attempts'] ?? 0) < 1 || ($data['max_attempts'] ?? 0) > (int) config('quiz.max_attempts')) {
            throw new ApiException('Batas percobaan kuis tidak valid.', 'VALIDATION_ERROR', 422);
        }
    }
}
