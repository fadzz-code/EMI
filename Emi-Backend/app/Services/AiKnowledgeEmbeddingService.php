<?php

namespace App\Services;

use App\Models\AiKnowledgeChunk;
use App\Services\Ai\EmbeddingProviderResolver;
use Illuminate\Support\Facades\Schema;
use Throwable;

class AiKnowledgeEmbeddingService
{
    public function __construct(private readonly EmbeddingProviderResolver $resolver) {}

    public function vectorStorageAvailable(): bool
    {
        try {
            return Schema::hasColumn('ai_knowledge_chunks', 'embedding');
        } catch (Throwable) {
            return false;
        }
    }

    public function providerAvailable(): bool
    {
        try {
            return $this->resolver->resolve()->isAvailable();
        } catch (Throwable) {
            return false;
        }
    }

    public function embeddingHash(AiKnowledgeChunk $chunk): string
    {
        return hash('sha256', implode('|', [
            hash('sha256', $chunk->content),
            (string) config('ai.embedding.provider', 'none'),
            (string) config('ai.embedding.model', 'gemini-embedding-001'),
            (string) config('ai.embedding.dimensions', 768),
        ]));
    }

    public function embed(AiKnowledgeChunk $chunk, bool $force = false): array
    {
        $hash = $this->embeddingHash($chunk);

        if (! $force && $chunk->embedding_hash === $hash && $chunk->embedding_error === null) {
            return ['status' => 'skipped', 'error' => null];
        }

        if (! $this->vectorStorageAvailable()) {
            return ['status' => 'failed', 'error' => 'Kolom embedding belum tersedia.'];
        }

        try {
            $provider = $this->resolver->resolve();

            if (! $provider->isAvailable()) {
                return ['status' => 'failed', 'error' => 'Provider embedding belum tersedia.'];
            }

            $result = $provider->embedDocument($chunk->content);

            if (! $result->success) {
                $chunk->forceFill([
                    'embedding_error' => $result->error ?? 'Embedding gagal.',
                    'embedding_provider' => $result->provider,
                    'embedding_model' => $result->model,
                    'embedding_dimensions' => $result->dimensions ?: null,
                ])->save();

                return ['status' => 'failed', 'error' => $result->error ?? 'Embedding gagal.'];
            }

            $chunk->forceFill([
                'embedding' => '['.implode(',', array_map(fn (float $value): string => rtrim(rtrim(sprintf('%.10F', $value), '0'), '.'), $result->vector)).']',
                'embedding_provider' => $result->provider,
                'embedding_model' => $result->model,
                'embedding_dimensions' => $result->dimensions,
                'embedded_at' => now(),
                'embedding_hash' => $hash,
                'embedding_error' => null,
            ])->save();

            return ['status' => 'succeeded', 'error' => null];
        } catch (Throwable $exception) {
            try {
                $chunk->forceFill(['embedding_error' => $exception->getMessage()])->save();
            } catch (Throwable) {
            }

            return ['status' => 'failed', 'error' => $exception->getMessage()];
        }
    }
}
