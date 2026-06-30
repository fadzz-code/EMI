<?php

namespace App\Services\Ai;

use App\Models\AiKnowledgeItem;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

class FreeAiAnswerProvider implements AiAnswerProviderInterface
{
    public function __construct(
        private readonly string $provider,
        private readonly ?string $apiKey,
        private readonly ?string $model,
        private readonly int $timeoutSeconds,
    ) {}

    public function generateAnswer(string $question, AiKnowledgeItem $reference): AiAnswerResult
    {
        if (! in_array($this->provider, ['gemini', 'groq'], true)) {
            return AiAnswerResult::fallback('free_ai_disabled');
        }

        if (! $this->apiKey) {
            return AiAnswerResult::fallback('free_ai_unavailable');
        }

        $prompt = $this->prompt($question, $reference);

        try {
            return match ($this->provider) {
                'gemini' => $this->generateGemini($prompt),
                'groq' => $this->generateGroq($prompt),
                default => AiAnswerResult::fallback('free_ai_disabled'),
            };
        } catch (Throwable $exception) {
            Log::warning('Free AI provider failed.', [
                'provider' => $this->provider,
                'exception' => $exception::class,
                'message' => $exception->getMessage(),
            ]);

            return AiAnswerResult::fallback('free_ai_error');
        }
    }

    public function prompt(string $question, AiKnowledgeItem $reference): string
    {
        return implode("\n", [
            'Anda adalah asisten EMI.',
            'Jawab hanya berdasarkan REFERENSI BASIS AI yang diberikan.',
            'Jangan gunakan pengetahuan umum di luar referensi.',
            'Jika referensi tidak cukup untuk menjawab, katakan:',
            '"Saya belum menemukan jawaban dari Basis AI yang tersedia."',
            '',
            'Pertanyaan siswa:',
            $question,
            '',
            'Referensi Basis AI:',
            'Judul: '.$reference->title,
            'Kategori: '.($reference->category ?? 'Umum'),
            'Konten:',
            $reference->content,
            '',
            'Tulis jawaban singkat, jelas, ramah untuk siswa.',
        ]);
    }

    private function generateGemini(string $prompt): AiAnswerResult
    {
        $model = $this->model ?: 'gemini-1.5-flash';
        $response = Http::timeout($this->timeoutSeconds)
            ->withQueryParameters(['key' => $this->apiKey])
            ->post("https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent", [
                'contents' => [
                    [
                        'parts' => [
                            ['text' => $prompt],
                        ],
                    ],
                ],
            ]);

        if (! $response->successful()) {
            return AiAnswerResult::fallback('free_ai_error');
        }

        $answer = data_get($response->json(), 'candidates.0.content.parts.0.text');

        return $this->answerResult($answer, $prompt);
    }

    private function generateGroq(string $prompt): AiAnswerResult
    {
        $model = $this->model ?: 'llama-3.1-8b-instant';
        $response = Http::timeout($this->timeoutSeconds)
            ->withToken((string) $this->apiKey)
            ->post('https://api.groq.com/openai/v1/chat/completions', [
                'model' => $model,
                'messages' => [
                    ['role' => 'user', 'content' => $prompt],
                ],
                'temperature' => 0.2,
            ]);

        if (! $response->successful()) {
            return AiAnswerResult::fallback('free_ai_error');
        }

        $answer = data_get($response->json(), 'choices.0.message.content');

        return $this->answerResult($answer, $prompt);
    }

    private function answerResult(?string $answer, string $prompt): AiAnswerResult
    {
        $trimmed = trim((string) $answer);

        if ($trimmed === '') {
            return AiAnswerResult::fallback('free_ai_error');
        }

        return AiAnswerResult::success($trimmed, $this->provider, $prompt);
    }
}
