<?php

namespace App\Services;

use App\Models\AiKnowledgeChunk;
use App\Models\AiKnowledgeItem;
use App\Models\User;
use App\Services\Ai\AiAnswerProviderResolver;
use Illuminate\Support\Collection;
use Illuminate\Support\Str;

class ChatbotService
{
    private const MINIMUM_CONFIDENCE = 8;

    private const TOP_K = 3;

    private const STOPWORDS = [
        'apa', 'itu', 'yang', 'dari', 'dengan', 'untuk', 'bagaimana', 'cara', 'adalah', 'ini', 'dan', 'atau', 'di', 'ke', 'pada', 'dalam', 'tentang', 'jelaskan', 'sebutkan', 'suku', 'mekongga',
    ];

    public function __construct(
        private readonly DefaultExtractiveAnswerProvider $defaultProvider,
        private readonly AiAnswerProviderResolver $providerResolver,
        private readonly AiKnowledgeChunkingService $chunkingService,
        private readonly DictionaryRetriever $dictionaryRetriever,
    ) {}

    public function respond(User $student, string $message): array
    {
        $dictionaryMatch = $this->dictionaryRetriever->retrieve($message);

        if ($dictionaryMatch !== null) {
            return $dictionaryMatch;
        }

        $match = $this->findBestPublishedReferences($message);

        if ($match === null) {
            return $this->defaultProvider->answer(null, $message);
        }

        $providerResult = $this->providerResolver->resolve()->generateAnswer($message, $match['item'], $match['chunks']);

        if ($providerResult->success && $providerResult->answer) {
            return $this->defaultProvider->answerFromProvider(
                $match['item'],
                $providerResult->answer,
                $providerResult->mode,
                $providerResult->provider,
                $match['confidence'],
                $match['chunks'],
            );
        }

        return $this->defaultProvider->answerFromChunks(
            $match['chunks'],
            $message,
            $match['confidence'],
            $match['keywords'],
            $providerResult->fallbackReason,
        );
    }

    private function findBestPublishedReferences(string $message): ?array
    {
        $keywords = $this->keywords($message);

        if ($keywords->isEmpty()) {
            return null;
        }

        AiKnowledgeItem::query()
            ->published()
            ->doesntHave('chunks')
            ->get()
            ->each(fn (AiKnowledgeItem $item) => $this->chunkingService->rebuild($item));

        $matches = AiKnowledgeChunk::query()
            ->with('knowledgeItem')
            ->whereHas('knowledgeItem', fn ($query) => $query->published())
            ->get()
            ->map(function (AiKnowledgeChunk $chunk) use ($keywords, $message): array {
                $item = $chunk->knowledgeItem;

                return [
                    'item' => $item,
                    'chunk' => $chunk,
                    'confidence' => $this->score($item, $chunk, $keywords, $message),
                    'keywords' => $keywords,
                ];
            })
            ->filter(fn (array $result): bool => $result['confidence'] >= self::MINIMUM_CONFIDENCE)
            ->sortByDesc('confidence')
            ->take(self::TOP_K)
            ->values();

        if ($matches->isEmpty()) {
            return null;
        }

        $best = $matches->first();

        return [
            'item' => $best['item'],
            'confidence' => $best['confidence'],
            'keywords' => $keywords,
            'chunks' => $matches->all(),
        ];
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

        return $score;
    }

    private function keywords(string $value): Collection
    {
        return collect(preg_split('/\s+/u', $this->normalize($value)) ?: [])
            ->map(fn (string $word): string => trim($word))
            ->filter(fn (string $word): bool => mb_strlen($word) >= 3)
            ->reject(fn (string $word): bool => in_array($word, self::STOPWORDS, true))
            ->unique()
            ->values();
    }

    private function normalize(string $value): string
    {
        return trim((string) preg_replace('/\s+/u', ' ', (string) preg_replace('/[^\pL\pN\s]+/u', ' ', Str::lower($value))));
    }
}
