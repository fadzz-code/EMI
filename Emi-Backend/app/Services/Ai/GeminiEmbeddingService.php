<?php

namespace App\Services\Ai;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Throwable;

class GeminiEmbeddingService
{
    protected string $apiKey;

    protected string $model;

    protected int $timeoutSeconds;

    public function __construct()
    {
        $this->apiKey = (string) config('services.gemini.api_key', env('GEMINI_API_KEY', ''));
        // text-embedding-004 adalah model standar resmi Google untuk pgvector
        $this->model = (string) config('services.gemini.embedding_model', env('GEMINI_EMBEDDING_MODEL', 'text-embedding-004'));
        $this->timeoutSeconds = (int) config('services.gemini.timeout', env('GEMINI_TIMEOUT', 15));
    }

    /**
     * Mengubah teks menjadi array Float Vector menggunakan Gemini API.
     *
     * @return array<float> Array dari nilai vektor (misal: 768 dimensi).
     */
    public function generateEmbedding(string $text): array
    {
        if (empty($this->apiKey)) {
            Log::error('Gemini Embedding Error: GEMINI_API_KEY belum diatur di file .env');

            return [];
        }

        $cleanedText = trim((string) preg_replace('/\s+/', ' ', $text));

        if (empty($cleanedText)) {
            return [];
        }

        $url = "https://generativelanguage.googleapis.com/v1beta/models/{$this->model}:embedContent";

        $payload = [
            'model' => "models/{$this->model}",
            'content' => [
                'parts' => [
                    ['text' => $cleanedText],
                ],
            ],
        ];

        try {
            $response = Http::timeout($this->timeoutSeconds)
                ->withQueryParameters(['key' => $this->apiKey])
                ->post($url, $payload);

            if ($response->successful()) {
                $values = data_get($response->json(), 'embedding.values', []);
                if (is_array($values) && ! empty($values)) {
                    return $values;
                }
            }

            Log::error("Gemini Embedding API Error (Status {$response->status()}): ".$response->body());

        } catch (Throwable $e) {
            Log::error('Gemini Embedding Exception: '.$e->getMessage());
        }

        return [];
    }
}
