<?php

namespace App\Services;

use App\Models\AiKnowledgeChunk;
use App\Models\AiKnowledgeItem;
use Illuminate\Support\Collection;
use Illuminate\Support\Str;

class DefaultExtractiveAnswerProvider
{
    public const FALLBACK_ANSWER = 'Saya belum menemukan jawaban dari Basis AI yang tersedia.';

    public function answer(?AiKnowledgeItem $item, string $message, int $confidence = 0, ?Collection $keywords = null, ?string $fallbackReason = null): array
    {
        if ($item === null) {
            return [
                'answer' => self::FALLBACK_ANSWER,
                'source' => null,
                'matched' => false,
                'mode' => 'default_extractive',
                'provider' => 'default',
                'confidence' => 0,
            ];
        }

        $searchKeywords = $keywords ?? $this->keywords($message);

        return [
            'answer' => 'Berdasarkan Basis AI EMI, berikut informasi yang ditemukan: '.$this->excerpt($item->content, $searchKeywords),
            'source' => [
                'id' => $item->id,
                'title' => $item->title,
                'category' => $item->category,
                'source_type' => $item->source_type,
                'source_url' => $item->source_url,
            ],
            'matched' => true,
            'mode' => 'default_extractive',
            'provider' => 'default',
            'confidence' => $confidence,
            'fallback_reason' => $fallbackReason,
        ];
    }

    public function answerFromProvider(AiKnowledgeItem $item, string $answer, string $mode, string $provider, int $confidence = 0, array $chunks = []): array
    {
        $source = $chunks[0] ?? null;

        return [
            'answer' => $answer,
            'source' => $source ? $this->sourceFromChunk($source['item'], $source['chunk'], $source) : $this->sourceFromItem($item),
            'sources' => $this->sourcesFromChunks($chunks),
            'matched' => true,
            'mode' => $mode,
            'provider' => $provider,
            'confidence' => $confidence,
        ];
    }

    public function answerFromChunks(array $chunks, string $message, int $confidence = 0, ?Collection $keywords = null, ?string $fallbackReason = null): array
    {
        if ($chunks === []) {
            return $this->answer(null, $message);
        }

        $best = $chunks[0];
        $searchKeywords = $keywords ?? $this->keywords($message);

        return [
            'answer' => 'Berdasarkan Basis AI EMI, berikut informasi yang ditemukan: '.$this->excerpt($best['chunk']->content, $searchKeywords),
            'source' => $this->sourceFromChunk($best['item'], $best['chunk'], $best),
            'sources' => $this->sourcesFromChunks($chunks),
            'matched' => true,
            'mode' => 'default_extractive',
            'provider' => 'default',
            'confidence' => $confidence,
            'fallback_reason' => $fallbackReason,
        ];
    }

    private function sourceFromItem(AiKnowledgeItem $item): array
    {
        return [
            'id' => $item->id,
            'title' => $item->title,
            'category' => $item->category,
            'source_type' => $item->source_type,
            'source_url' => $item->source_url,
        ];
    }

    private function sourceFromChunk(AiKnowledgeItem $item, AiKnowledgeChunk $chunk, array $metadata = []): array
    {
        return array_filter([
            ...$this->sourceFromItem($item),
            'chunk_id' => $chunk->id,
            'chunk_index' => $chunk->chunk_index,
            'retrieval_mode' => $metadata['retrieval_mode'] ?? null,
            'similarity_score' => $metadata['similarity_score'] ?? null,
            'distance' => $metadata['distance'] ?? null,
        ], fn ($value): bool => $value !== null);
    }

    private function sourcesFromChunks(array $chunks): array
    {
        return collect($chunks)->map(fn (array $chunk): array => $this->sourceFromChunk($chunk['item'], $chunk['chunk'], $chunk))->values()->all();
    }

    private function excerpt(string $content, Collection $keywords): string
    {
        $sentences = collect(preg_split('/(?<=[.!?])\s+/u', trim($content)) ?: [])
            ->map(fn (string $sentence): string => trim($sentence))
            ->filter();

        $matched = $sentences->sortByDesc(function (string $sentence) use ($keywords): int {
            $normalized = $this->normalize($sentence);

            return $keywords->sum(fn (string $keyword): int => Str::contains($normalized, $keyword) ? 1 : 0);
        })->first(function (string $sentence) use ($keywords): bool {
            $normalized = $this->normalize($sentence);

            return $keywords->contains(fn (string $keyword): bool => Str::contains($normalized, $keyword));
        });

        return Str::limit($matched ?: $content, 700);
    }

    private function keywords(string $value): Collection
    {
        return collect(preg_split('/\s+/u', $this->normalize($value)) ?: [])
            ->map(fn (string $word): string => trim($word))
            ->filter(fn (string $word): bool => mb_strlen($word) >= 3)
            ->reject(fn (string $word): bool => in_array($word, ['apa', 'itu', 'yang', 'dari', 'dengan', 'untuk', 'bagaimana', 'cara', 'adalah', 'ini', 'dan', 'atau', 'suku', 'bahasa', 'budaya', 'mekongga'], true))
            ->unique()
            ->values();
    }

    private function normalize(string $value): string
    {
        return trim((string) preg_replace('/\s+/u', ' ', (string) preg_replace('/[^\pL\pN\s]+/u', ' ', Str::lower($value))));
    }
}
