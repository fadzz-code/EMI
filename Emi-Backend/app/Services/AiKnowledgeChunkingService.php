<?php

namespace App\Services;

use App\Models\AiKnowledgeItem;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class AiKnowledgeChunkingService
{
    private const CHUNK_SIZE = 1000;

    private const OVERLAP_SIZE = 150;

    private const MIN_CHUNK_LENGTH = 80;

    public function rebuild(AiKnowledgeItem $item): int
    {
        $content = $this->normalize($item->content);
        $chunks = $this->chunk($content);

        return DB::transaction(function () use ($item, $chunks): int {
            $item->chunks()->delete();

            foreach ($chunks as $index => $chunk) {
                $item->chunks()->create([
                    'chunk_index' => $index,
                    'content' => $chunk,
                    'content_hash' => hash('sha256', $chunk),
                    'character_count' => mb_strlen($chunk),
                    'token_estimate' => max(1, (int) ceil(mb_strlen($chunk) / 4)),
                    'metadata' => [
                        'source_title' => $item->title,
                        'source_type' => $item->source_type,
                        'source_url' => $item->source_url,
                        'category' => $item->category,
                        'page' => null,
                        'section' => null,
                    ],
                ]);
            }

            return $chunks->count();
        });
    }

    public function ensureChunks(AiKnowledgeItem $item): int
    {
        if ($item->chunks()->exists()) {
            return $item->chunks()->count();
        }

        return $this->rebuild($item);
    }

    public function chunk(string $content): Collection
    {
        $normalized = $this->normalize($content);

        if ($normalized === '') {
            return collect();
        }

        if (mb_strlen($normalized) <= self::CHUNK_SIZE) {
            return collect([$normalized]);
        }

        $sentences = collect(preg_split('/(?<=[.!?])\s+/u', $normalized) ?: [])
            ->map(fn (string $sentence): string => trim($sentence))
            ->filter()
            ->values();

        if ($sentences->isEmpty()) {
            return collect(mb_str_split($normalized, self::CHUNK_SIZE));
        }

        $chunks = collect();
        $current = '';

        foreach ($sentences as $sentence) {
            if (mb_strlen($sentence) > self::CHUNK_SIZE) {
                if ($current !== '') {
                    $chunks->push($current);
                    $current = $this->overlap($current);
                }

                foreach (mb_str_split($sentence, self::CHUNK_SIZE) as $part) {
                    $chunks->push(trim($part));
                }

                $current = '';

                continue;
            }

            $candidate = trim($current.' '.$sentence);

            if (mb_strlen($candidate) > self::CHUNK_SIZE && $current !== '') {
                $chunks->push($current);
                $current = trim($this->overlap($current).' '.$sentence);
            } else {
                $current = $candidate;
            }
        }

        if ($current !== '') {
            $chunks->push($current);
        }

        $filtered = $chunks
            ->map(fn (string $chunk): string => $this->normalize($chunk))
            ->filter(fn (string $chunk): bool => mb_strlen($chunk) >= self::MIN_CHUNK_LENGTH)
            ->values();

        return $filtered->isNotEmpty() ? $filtered : collect([$normalized]);
    }

    public function normalize(string $content): string
    {
        return trim((string) preg_replace('/\s+/u', ' ', $content));
    }

    private function overlap(string $chunk): string
    {
        return trim(mb_substr($chunk, max(0, mb_strlen($chunk) - self::OVERLAP_SIZE)));
    }
}
