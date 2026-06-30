<?php

namespace App\Services;

use App\Models\AiKnowledgeItem;
use App\Models\User;
use Illuminate\Support\Collection;
use Illuminate\Support\Str;

class ChatbotService
{
    public function __construct(private readonly DefaultExtractiveAnswerProvider $defaultProvider) {}

    public function respond(User $student, string $message): array
    {
        $item = $this->findBestPublishedReference($message);

        return $this->defaultProvider->answer($item, $message);
    }

    private function findBestPublishedReference(string $message): ?AiKnowledgeItem
    {
        $keywords = $this->keywords($message);

        if ($keywords->isEmpty()) {
            return null;
        }

        return AiKnowledgeItem::query()
            ->published()
            ->get()
            ->map(fn (AiKnowledgeItem $item): array => ['item' => $item, 'score' => $this->score($item, $keywords)])
            ->filter(fn (array $result): bool => $result['score'] > 0)
            ->sortByDesc('score')
            ->first()['item'] ?? null;
    }

    private function score(AiKnowledgeItem $item, Collection $keywords): int
    {
        $title = $this->normalize($item->title);
        $category = $this->normalize($item->category ?? '');
        $content = $this->normalize($item->content);

        return $keywords->sum(function (string $keyword) use ($title, $category, $content): int {
            $score = 0;
            $score += Str::contains($title, $keyword) ? 5 : 0;
            $score += Str::contains($category, $keyword) ? 4 : 0;
            $score += Str::contains($content, $keyword) ? 1 : 0;

            return $score;
        });
    }

    private function keywords(string $value): Collection
    {
        return collect(preg_split('/\s+/u', $this->normalize($value)) ?: [])
            ->map(fn (string $word): string => trim($word))
            ->filter(fn (string $word): bool => mb_strlen($word) >= 3)
            ->reject(fn (string $word): bool => in_array($word, ['apa', 'itu', 'dan', 'yang', 'dari', 'untuk', 'dengan', 'tentang', 'adalah'], true))
            ->unique()
            ->values();
    }

    private function normalize(string $value): string
    {
        return trim((string) preg_replace('/[^\pL\pN\s]+/u', ' ', Str::lower($value)));
    }
}
