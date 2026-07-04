<?php

namespace App\Services;

use App\Models\AiKnowledgeChunk;
use App\Models\AiKnowledgeItem;
use Illuminate\Support\Collection;
use Illuminate\Support\Str;

class KeywordChunkRetriever
{
    private const MINIMUM_CONFIDENCE = 8;

    private const STOPWORDS = [
        'apa', 'itu', 'yang', 'dari', 'dengan', 'untuk', 'bagaimana', 'cara', 'adalah', 'ini', 'dan', 'atau', 'di', 'ke', 'pada', 'dalam', 'tentang', 'jelaskan', 'sebutkan', 'suku', 'mekongga',
    ];

    public function retrieve(string $message): array
    {
        $keywords = $this->keywords($message);

        if ($keywords->isEmpty()) {
            return [];
        }

        return AiKnowledgeChunk::query()
            ->with('knowledgeItem')
            ->whereHas('knowledgeItem', fn ($query) => $query->published())
            ->get()
            ->filter(fn (AiKnowledgeChunk $chunk): bool => ($chunk->metadata['searchable'] ?? true) !== false)
            ->map(function (AiKnowledgeChunk $chunk) use ($keywords, $message): array {
                $item = $chunk->knowledgeItem;

                return [
                    'item' => $item,
                    'chunk' => $chunk,
                    'confidence' => $this->score($item, $chunk, $keywords, $message),
                    'keywords' => $keywords,
                    'retrieval_mode' => 'keyword',
                ];
            })
            ->filter(fn (array $result): bool => $result['confidence'] >= self::MINIMUM_CONFIDENCE)
            ->sortByDesc('confidence')
            ->take(max(1, (int) config('ai.vector_retrieval.keyword_top_k', 5)))
            ->values()
            ->all();
    }

    public function keywords(string $value): Collection
    {
        return collect(preg_split('/\s+/u', $this->normalize($value)) ?: [])
            ->map(fn (string $word): string => trim($word))
            ->filter(fn (string $word): bool => mb_strlen($word) >= 3)
            ->reject(fn (string $word): bool => in_array($word, self::STOPWORDS, true))
            ->unique()
            ->values();
    }

    private function score(AiKnowledgeItem $item, AiKnowledgeChunk $chunk, Collection $keywords, string $message): int
    {
        $title = $this->normalize($item->title);
        $category = $this->normalize($item->category ?? '');
        $sourceType = $this->normalize($item->source_type);
        $content = $this->normalize($chunk->content);
        $phrase = $this->normalize($message);
        $score = 0;
        $matchedKeywords = 0;

        if ($phrase !== '' && Str::contains($title, $phrase)) {
            $score += 24;
        }

        if ($phrase !== '' && Str::contains($content, $phrase)) {
            $score += 18;
        }

        foreach ($keywords as $keyword) {
            $matched = false;

            if (Str::contains($title, $keyword)) {
                $score += 8;
                $matched = true;
            }

            if (Str::contains($category, $keyword)) {
                $score += 5;
                $matched = true;
            }

            if (Str::contains($sourceType, $keyword)) {
                $score += 2;
                $matched = true;
            }

            $contentCount = substr_count($content, $keyword);
            if ($contentCount > 0) {
                $score += min(6, $contentCount * 2);
                $matched = true;
            }

            if ($matched) {
                $matchedKeywords++;
            }
        }

        if ($matchedKeywords >= 2) {
            $score += $matchedKeywords * 3;
        }

        $pageType = $chunk->metadata['page_type'] ?? 'body';
        if ($pageType === 'body') {
            $score += 4;
        }
        if (in_array($pageType, ['table_of_contents', 'front_matter', 'copyright', 'bibliography', 'cover', 'low_quality_ocr'], true)) {
            $score -= 20;
        }

        return $score;
    }

    private function normalize(string $value): string
    {
        return trim((string) preg_replace('/\s+/u', ' ', (string) preg_replace('/[^\pL\pN\s]+/u', ' ', Str::lower($value))));
    }
}
