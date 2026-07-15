<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\ClassQuiz;
use App\Models\QuizQuestion;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class QuizQuestionService
{
    public function __construct(
        private readonly AuditLogService $auditLogService,
        private readonly QuizQuestionValidationService $validationService,
    ) {}

    public function create(ClassQuiz $quiz, array $data, User $actor, Request $request): QuizQuestion
    {
        $this->assertEditable($quiz);
        $this->validationService->validate($data);

        return DB::transaction(function () use ($quiz, $data, $actor, $request) {
            $payload = $this->payload($data);

            if (! isset($data['order_number'])) {
                $maxOrder = $quiz->questions()->lockForUpdate()->orderByDesc('order_number')->value('order_number') ?? 0;
                $payload['order_number'] = $maxOrder + 1;
            } else {
                $exists = $quiz->questions()->lockForUpdate()->where('order_number', $data['order_number'])->exists();
                if ($exists) {
                    throw new ApiException('Urutan pertanyaan tersebut sudah digunakan.', 'QUIZ_QUESTION_ORDER_ALREADY_USED', 422);
                }
            }

            $question = $quiz->questions()->create($payload + ['created_by' => $actor->id]);
            $this->syncOptions($question, $data['options'] ?? []);
            $this->auditLogService->record('quiz_question.created', $question, $actor, null, $question->only(['class_quiz_id', 'question_type', 'order_number']), [], $request);

            return $question->refresh()->load('options', 'imageMedia');
        });
    }

    public function update(QuizQuestion $question, array $data, User $actor, Request $request): QuizQuestion
    {
        $question->load('classQuiz', 'options');
        $this->assertEditable($question->classQuiz);

        $merged = array_merge($question->only(['question_type', 'question_text', 'image_media_id', 'correct_answer_text', 'use_fuzzy_matching', 'fuzzy_threshold', 'points', 'order_number', 'explanation']), $data);
        $merged['options'] = $data['options'] ?? $question->options->map(fn ($option) => $option->only(['option_text', 'is_correct', 'order_number']))->all();
        $this->validationService->validate($merged);

        return DB::transaction(function () use ($question, $data, $actor, $request) {
            $old = $question->only(['question_type', 'question_text', 'order_number']);
            $question->fill($this->payload($data));
            $question->updated_by = $actor->id;
            $question->save();
            if (array_key_exists('options', $data)) {
                $this->syncOptions($question, $data['options'] ?? []);
            }
            $this->auditLogService->record('quiz_question.updated', $question, $actor, $old, $question->only(['question_type', 'question_text', 'order_number']), [], $request);

            return $question->refresh()->load('options', 'imageMedia');
        });
    }

    public function delete(QuizQuestion $question, User $actor, Request $request): void
    {
        $question->load('classQuiz');
        $this->assertEditable($question->classQuiz);

        DB::transaction(function () use ($question, $actor, $request) {
            $question->options()->delete();
            $question->delete();
            $this->auditLogService->record('quiz_question.deleted', $question, $actor, null, ['deleted_at' => now()->toISOString()], [], $request);
        });
    }

    public function reorder(ClassQuiz $quiz, array $questionIds, User $actor, Request $request): void
    {
        $this->assertEditable($quiz);
        $existing = $quiz->questions()->pluck('id')->all();
        sort($existing);
        $given = $questionIds;
        sort($given);

        if ($existing !== $given) {
            throw new ApiException('Daftar soal tidak sesuai.', 'INVALID_QUESTION_ORDER', 422);
        }

        DB::transaction(function () use ($quiz, $questionIds, $actor, $request) {
            foreach ($questionIds as $index => $id) {
                $quiz->questions()->whereKey($id)->update(['order_number' => 1000 + $index + 1]);
            }
            foreach ($questionIds as $index => $id) {
                $quiz->questions()->whereKey($id)->update(['order_number' => $index + 1, 'updated_by' => $actor->id]);
            }
            $this->auditLogService->record('quiz_question.reordered', $quiz, $actor, null, ['question_ids' => $questionIds], [], $request);
        });
    }

    private function assertEditable(ClassQuiz $quiz): void
    {
        if ($quiz->status !== 'draft' || $quiz->attempts()->exists()) {
            throw new ApiException('Konten kuis terkunci.', 'QUIZ_CONTENT_LOCKED', 409);
        }
    }

    private function payload(array $data): array
    {
        return collect($data)->only(['question_type', 'question_text', 'image_media_id', 'correct_answer_text', 'use_fuzzy_matching', 'fuzzy_threshold', 'points', 'order_number', 'explanation'])->all();
    }

    private function syncOptions(QuizQuestion $question, array $options): void
    {
        $question->options()->delete();
        foreach ($options as $option) {
            $question->options()->create([
                'option_text' => $option['option_text'],
                'is_correct' => (bool) ($option['is_correct'] ?? false),
                'order_number' => $option['order_number'],
            ]);
        }
    }
}
