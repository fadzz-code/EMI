<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\QuizTemplate;
use App\Models\QuizTemplateOption;
use App\Models\QuizTemplateQuestion;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class QuizTemplateQuestionService
{
    public function __construct(private readonly AuditLogService $auditLogService, private readonly QuizQuestionValidationService $validationService) {}

    public function create(QuizTemplate $template, array $data, User $actor, Request $request): QuizTemplateQuestion
    {
        $this->assertEditable($template);
        $this->validationService->validate($data);

        return DB::transaction(function () use ($template, $data, $actor, $request) {
            $question = $template->questions()->create($this->payload($data) + ['created_by' => $actor->id]);
            $this->syncOptions($question, $data['options'] ?? []);
            $this->auditLogService->record('quiz_template_question.created', $question, $actor, null, ['question_type' => $question->question_type], [], $request);

            return $question->load('options', 'imageMedia');
        });
    }

    public function update(QuizTemplateQuestion $question, array $data, User $actor, Request $request): QuizTemplateQuestion
    {
        $question->loadMissing('quizTemplate');
        $this->assertEditable($question->quizTemplate);
        $merged = array_merge($question->toArray(), $data);
        if (! array_key_exists('options', $merged)) {
            $merged['options'] = $question->options()->get()->map(fn ($option) => $option->only(['option_text', 'is_correct', 'order_number']))->all();
        }
        $this->validationService->validate($merged);

        return DB::transaction(function () use ($question, $data, $actor, $request) {
            $old = $question->only(['question_type', 'question_text']);
            $question->fill($this->payload($data, false));
            $question->updated_by = $actor->id;
            $question->save();
            if (array_key_exists('options', $data)) {
                $question->options()->delete();
                $this->syncOptions($question, $data['options']);
            }
            $this->auditLogService->record('quiz_template_question.updated', $question, $actor, $old, $question->only(['question_type', 'question_text']), [], $request);

            return $question->refresh()->load('options', 'imageMedia');
        });
    }

    public function delete(QuizTemplateQuestion $question, User $actor, Request $request): void
    {
        $question->loadMissing('quizTemplate');
        $this->assertEditable($question->quizTemplate);
        $question->delete();
        $this->auditLogService->record('quiz_template_question.deleted', $question, $actor, null, ['deleted_at' => now()->toISOString()], [], $request);
    }

    public function reorder(QuizTemplate $template, array $ids, User $actor, Request $request): void
    {
        $this->assertEditable($template);
        DB::transaction(function () use ($template, $ids, $actor, $request) {
            $active = $template->questions()->pluck('id')->all();
            sort($active);
            $given = $ids;
            sort($given);
            if ($active !== $given || count($ids) !== count(array_unique($ids))) {
                throw new ApiException('Urutan soal tidak valid.', 'INVALID_ORDER', 422);
            }
            foreach ($ids as $index => $id) {
                QuizTemplateQuestion::query()->whereKey($id)->update(['order_number' => 1000 + $index + 1]);
            }
            foreach ($ids as $index => $id) {
                QuizTemplateQuestion::query()->whereKey($id)->update(['order_number' => $index + 1, 'updated_by' => $actor->id]);
            }
            $this->auditLogService->record('quiz_template_question.reordered', $template, $actor, null, ['question_ids' => $ids], [], $request);
        });
    }

    private function payload(array $data, bool $creating = true): array
    {
        $payload = collect($data)->only(['question_type', 'question_text', 'image_media_id', 'correct_answer_text', 'use_fuzzy_matching', 'fuzzy_threshold', 'points', 'order_number', 'explanation'])->all();
        if ($creating && ! isset($payload['order_number'])) {
            $payload['order_number'] = 1;
        }
        if (($payload['question_type'] ?? null) === 'multiple_choice') {
            $payload['correct_answer_text'] = null;
            $payload['use_fuzzy_matching'] = false;
            $payload['fuzzy_threshold'] = null;
        }

        return $payload;
    }

    private function syncOptions(QuizTemplateQuestion $question, array $options): void
    {
        foreach ($options as $option) {
            QuizTemplateOption::query()->create([
                'quiz_template_question_id' => $question->id,
                'option_text' => $option['option_text'],
                'is_correct' => (bool) $option['is_correct'],
                'order_number' => $option['order_number'],
            ]);
        }
    }

    private function assertEditable(QuizTemplate $template): void
    {
        if ($template->status === 'published') {
            throw new ApiException('Konten template kuis published terkunci.', 'QUIZ_CONTENT_LOCKED', 409);
        }
    }
}
