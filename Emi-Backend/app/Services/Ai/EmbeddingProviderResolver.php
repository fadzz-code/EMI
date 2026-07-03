<?php

namespace App\Services\Ai;

class EmbeddingProviderResolver
{
    public function resolve(): EmbeddingProviderInterface
    {
        $provider = (string) config('ai.embedding.provider', 'none');

        if ($provider !== 'gemini') {
            return new NullEmbeddingProvider;
        }

        $apiKey = config('ai.embedding.api_key');

        if (! $apiKey) {
            return new NullEmbeddingProvider;
        }

        return new GeminiEmbeddingProvider(
            provider: $provider,
            apiKey: $apiKey,
            model: (string) config('ai.embedding.model', 'gemini-embedding-001'),
            baseUrl: (string) config('ai.embedding.base_url', 'https://generativelanguage.googleapis.com/v1beta'),
            dimensions: max(1, (int) config('ai.embedding.dimensions', 768)),
            timeoutSeconds: max(1, (int) config('ai.embedding.timeout_seconds', 10)),
        );
    }
}
