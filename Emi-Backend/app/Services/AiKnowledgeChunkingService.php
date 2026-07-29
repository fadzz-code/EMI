<?php

namespace App\Services;

use App\Models\AiKnowledgeItem;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

class AiKnowledgeChunkingService
{
    public function __construct(private readonly AiPdfPageClassifier $pageClassifier) {}

    private const CHUNK_SIZE = 1000;

    private const OVERLAP_SIZE = 150;

    private const MIN_CHUNK_LENGTH = 80;

    public function rebuild(AiKnowledgeItem $item): int
    {
        $chunks = $item->sourcePages()->exists()
            ? $this->chunksFromSourcePages($item)
            : $this->chunk($this->normalize($item->content))->map(fn (string $chunk): array => [
                'content' => $chunk,
                'metadata' => $this->baseMetadata($item) + [
                    'page' => null,
                    'section' => null,
                ],
            ]);

        return DB::transaction(function () use ($item, $chunks): int {
            $item->chunks()->delete();

            foreach ($chunks as $index => $chunk) {
                $content = $chunk['content'];

                $item->chunks()->create([
                    'chunk_index' => $index,
                    'content' => $content,
                    'content_hash' => hash('sha256', $content),
                    'character_count' => mb_strlen($content),
                    'token_estimate' => max(1, (int) ceil(mb_strlen($content) / 4)),
                    'metadata' => $chunk['metadata'],
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

    private function chunksFromSourcePages(AiKnowledgeItem $item): Collection
    {
        return $item->sourcePages()->get()->flatMap(function ($page) use ($item): Collection {
            $metadata = $page->metadata ?? [];
            $classification = $this->pageClassifier->classify($page->content, $page->page_number);
            $pageType = $metadata['page_type'] ?? $classification['page_type'];
            $searchable = $metadata['searchable'] ?? $classification['searchable'];

            if ($metadata === [] || ! array_key_exists('page_type', $metadata) || ! array_key_exists('searchable', $metadata)) {
                $metadata = [
                    ...$metadata,
                    'page_type' => $pageType,
                    'searchable' => $searchable,
                    'skip_reason' => $metadata['skip_reason'] ?? $classification['skip_reason'],
                    'ocr_noise_score' => $metadata['ocr_noise_score'] ?? $classification['ocr_noise_score'],
                ];
                $page->forceFill(['metadata' => $metadata])->save();
            }

            if ($searchable === false) {
                return collect();
            }

            return $this->chunk($page->content)->map(fn (string $chunk): array => [
                'content' => $chunk,
                'metadata' => $this->baseMetadata($item) + [
                    'page_number' => $page->page_number,
                    'page_start' => $page->page_number,
                    'page_end' => $page->page_number,
                    'page_type' => $pageType,
                    'searchable' => true,
                    'ingestion_mode' => 'pdf_pages',
                    'source_page_id' => $page->id,
                ],
            ]);
        })->values();
    }

    private function baseMetadata(AiKnowledgeItem $item): array
    {
        return [
            'source_title' => $item->title,
            'source_type' => $item->source_type,
            'source_url' => $item->source_url,
            'category' => $item->category,
        ];
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
