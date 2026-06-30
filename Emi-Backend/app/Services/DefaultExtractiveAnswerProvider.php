<?php

namespace App\Services;

use App\Models\AiKnowledgeItem;
use Illuminate\Support\Collection;
use Illuminate\Support\Str;

class DefaultExtractiveAnswerProvider
{
    public const FALLBACK_ANSWER = 'Saya belum menemukan jawaban dari Basis AI yang tersedia.';

    public function answer(?AiKnowledgeItem $item, string $message, int $confidence = 0, ?Collection $keywords = null): array
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
        ];
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
