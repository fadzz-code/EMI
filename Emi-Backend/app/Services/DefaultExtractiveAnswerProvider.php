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

        $excerpt = $this->excerpt($best['chunk']->content, $searchKeywords);

        if ($excerpt === '') {
            return $this->answer(null, $message);
        }

        return [
            'answer' => 'Berdasarkan Basis AI EMI, berikut informasi yang ditemukan: '.$excerpt,
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
        $chunkMetadata = $chunk->metadata ?? [];

        return array_filter([
            ...$this->sourceFromItem($item),
            'chunk_id' => $chunk->id,
            'chunk_index' => $chunk->chunk_index,
            'page_number' => $chunkMetadata['page_number'] ?? null,
            'page_start' => $chunkMetadata['page_start'] ?? null,
            'page_end' => $chunkMetadata['page_end'] ?? null,
            'page_type' => $chunkMetadata['page_type'] ?? null,
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
        $parts = collect(preg_split('/(?<=[.!?])\s+|\R+/u', trim($content)) ?: [])
            ->map(fn (string $part): string => trim($part))
            ->filter(fn (string $part): bool => $this->isAnswerLikePart($part))
            ->values();

        if ($parts->isEmpty()) {
            return '';
        }

        $matched = $parts->sortByDesc(function (string $part) use ($keywords): int {
            $normalized = $this->normalize($part);

            return $keywords->sum(fn (string $keyword): int => Str::contains($normalized, $keyword) ? 1 : 0);
        })->filter(function (string $part) use ($keywords): bool {
            $normalized = $this->normalize($part);

            return $keywords->isEmpty() || $keywords->contains(fn (string $keyword): bool => Str::contains($normalized, $keyword));
        })->take(5)->values();

        $selected = $matched->isNotEmpty() ? $matched : $parts->take(3);

        return Str::limit($selected->implode(' '), 900);
    }

    private function isAnswerLikePart(string $part): bool
    {
        $normalized = $this->normalize($part);

        if (mb_strlen($normalized) < 40) {
            return false;
        }

        if (preg_match('/^(bab\s+[ivxlcdm]+|\d+(?:\.\d+)*)\b.*(\.{2,}|\s\d{1,3}$)/iu', $part)) {
            return false;
        }

        if (preg_match('/\.{3,}\s*\d+\s*$/u', $part)) {
            return false;
        }

        return true;
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
