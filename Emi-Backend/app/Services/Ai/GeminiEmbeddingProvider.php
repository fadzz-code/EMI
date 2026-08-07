<?php

namespace App\Services\Ai;

use Illuminate\Support\Facades\Http;
use Throwable;

class GeminiEmbeddingProvider implements EmbeddingProviderInterface
{
    public function __construct(
        private readonly string $provider,
        private readonly ?string $apiKey,
        private readonly string $model,
        private readonly string $baseUrl,
        private readonly int $dimensions,
        private readonly int $timeoutSeconds,
    ) {}

    public function isAvailable(): bool
    {
        return $this->provider === 'gemini' && filled($this->apiKey);
    }

    public function embedDocument(string $text): EmbeddingResult
    {
        return $this->embed($text, 'document', 'RETRIEVAL_DOCUMENT');
    }

    public function embedQuery(string $text): EmbeddingResult
    {
        return $this->embed($text, 'query', 'RETRIEVAL_QUERY');
    }

    private function embed(string $text, string $inputType, string $taskType): EmbeddingResult
    {
        if (! $this->isAvailable()) {
            return $this->failure('Provider embedding belum dikonfigurasi.', $inputType);
        }

        try {
            $usedModel = 'gemini/gemini-embedding-001';

            $response = Http::withHeaders([
                    'Content-Type' => 'application/json',
                    'Authorization' => 'Bearer ' . $this->apiKey,
                ])
                ->withOptions([
                    'verify' => false,
                    'curl' => [
                        CURLOPT_IPRESOLVE => CURL_IPRESOLVE_V4,
                    ]
                ])
                ->timeout(max(1, $this->timeoutSeconds))
                ->post($this->endpoint(), [
                    'model' => $usedModel,
                    'input' => $text 
                ]);

            if (! $response->successful()) {
                return $this->failure('Provider embedding mengembalikan respons gagal.', $inputType, [
                    'status' => $response->status(),
                    'body' => $response->body(),
                ]);
            }

            // Parsing response ala OpenAI Format dari Sumopod
            $values = data_get($response->json(), 'data.0.embedding');

            if (! is_array($values) || $values === []) {
                return $this->failure('Respons embedding tidak valid.', $inputType);
            }

            $vector = collect($values)
                ->filter(fn ($value): bool => is_numeric($value))
                ->map(fn ($value): float => (float) $value)
                ->values()
                ->all();

            if (count($vector) !== count($values)) {
                return $this->failure('Respons embedding berisi nilai tidak valid.', $inputType);
            }

            if ($this->dimensions > 0 && count($vector) !== $this->dimensions) {
                return $this->failure('Dimensi embedding tidak sesuai konfigurasi.', $inputType, [
                    'actual_dimensions' => count($vector),
                ]);
            }

            return EmbeddingResult::success($vector, $this->provider, $usedModel, count($vector), $inputType, [
                'task_type' => $taskType,
            ]);
        } catch (Throwable $e) {
            return $this->failure('Provider embedding tidak dapat dihubungi: ' . $e->getMessage(), $inputType);
        }
    }

    private function endpoint(): string
    {
        return 'https://ai.sumopod.com/v1/embeddings';
    }

    private function failure(string $error, string $inputType, array $metadata = []): EmbeddingResult
    {
        return EmbeddingResult::failure($error, $this->provider, 'gemini/gemini-embedding-001', $this->dimensions, $inputType, $metadata);
    }
}