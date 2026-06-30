<?php

namespace App\Services;

use App\Models\AiKnowledgeItem;
use App\Models\User;
use Illuminate\Support\Collection;
use Illuminate\Support\Str;

class ChatbotService
{
    private const MINIMUM_CONFIDENCE = 8;

    private const STOPWORDS = [
        'apa', 'itu', 'yang', 'dari', 'dengan', 'untuk', 'bagaimana', 'cara', 'adalah', 'ini', 'dan', 'atau', 'di', 'ke', 'pada', 'dalam', 'tentang', 'jelaskan', 'sebutkan', 'suku', 'bahasa', 'budaya', 'mekongga',
    ];

    public function __construct(private readonly DefaultExtractiveAnswerProvider $defaultProvider) {}

    public function respond(User $student, string $message): array
    {
        $match = $this->findBestPublishedReference($message);

        return $this->defaultProvider->answer(
            $match['item'] ?? null,
            $message,
            $match['confidence'] ?? 0,
            $match['keywords'] ?? collect(),
        );
    }

    private function findBestPublishedReference(string $message): ?array
    {
        $keywords = $this->keywords($message);

        if ($keywords->isEmpty()) {
            return null;
        }

        $match = AiKnowledgeItem::query()
            ->published()
            ->get()
            ->map(fn (AiKnowledgeItem $item): array => [
                'item' => $item,
                'confidence' => $this->score($item, $keywords, $message),
                'keywords' => $keywords,
            ])
            ->filter(fn (array $result): bool => $result['confidence'] >= self::MINIMUM_CONFIDENCE)
            ->sortByDesc('confidence')
            ->first();

        return $match ?: null;
    }

    private function score(AiKnowledgeItem $item, Collection $keywords, string $message): int
    {
        $title = $this->normalize($item->title);
        $category = $this->normalize($item->category ?? '');
        $content = $this->normalize($item->content);
        $phrase = $keywords->implode(' ');
        $score = 0;
        $matchedKeywords = 0;

        if ($phrase !== '' && Str::contains($title, $phrase)) {
            $score += 18;
        }

        foreach ($keywords as $keyword) {
            $matched = false;

            if (Str::contains($title, $keyword)) {
                $score += 8;
                $matched = true;
            }

            if (Str::contains($category, $keyword)) {
                $score += 4;
                $matched = true;
            }

            if (Str::contains($content, $keyword)) {
                $score += 2;
                $matched = true;
            }

            if ($matched) {
                $matchedKeywords++;
            }
        }

        if ($matchedKeywords >= 2) {
            $score += $matchedKeywords * 2;
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
