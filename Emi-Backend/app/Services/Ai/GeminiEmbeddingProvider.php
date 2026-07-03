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
            $response = Http::timeout(max(1, $this->timeoutSeconds))
                ->withQueryParameters(['key' => $this->apiKey])
                ->post($this->endpoint(), [
                    'model' => 'models/'.$this->model,
                    'content' => [
                        'parts' => [
                            ['text' => $text],
                        ],
                    ],
                    'taskType' => $taskType,
                    'outputDimensionality' => $this->dimensions,
                ]);

            if (! $response->successful()) {
                return $this->failure('Provider embedding mengembalikan respons gagal.', $inputType, [
                    'status' => $response->status(),
                ]);
            }

            $values = data_get($response->json(), 'embedding.values');

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

            if (count($vector) !== $this->dimensions) {
                return $this->failure('Dimensi embedding tidak sesuai konfigurasi.', $inputType, [
                    'actual_dimensions' => count($vector),
                ]);
            }

            return EmbeddingResult::success($vector, $this->provider, $this->model, $this->dimensions, $inputType, [
                'task_type' => $taskType,
            ]);
        } catch (Throwable) {
            return $this->failure('Provider embedding tidak dapat dihubungi.', $inputType);
        }
    }

    private function endpoint(): string
    {
        return rtrim($this->baseUrl, '/').'/models/'.$this->model.':embedContent';
    }

    private function failure(string $error, string $inputType, array $metadata = []): EmbeddingResult
    {
        return EmbeddingResult::failure($error, $this->provider, $this->model, $this->dimensions, $inputType, $metadata);
    }
}
