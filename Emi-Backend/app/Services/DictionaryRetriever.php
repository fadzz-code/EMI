<?php

namespace App\Services;

use App\Models\DictionaryEntry;
use Illuminate\Support\Str;

class DictionaryRetriever
{
    private const GENERIC_WORDS = [
        'apa', 'arti', 'artinya', 'kata', 'bahasa', 'mekongga', 'dari', 'untuk', 'terjemahan', 'padanan', 'kosakata', 'dalam', 'ke', 'yang', 'adalah', 'itu',
        'makna', 'maksud', 'maksudnya', 'dimaksud', 'dong', 'sih', 'nih', 'kok', 'loh', 'tuh', 'ya', 'yah',
    ];

    public function __construct(private readonly DictionaryNormalizer $normalizer) {}

    public function retrieve(string $message): ?array
    {
        $target = $this->target($message);

        if ($target === null) {
            return null;
        }

        $normalized = $this->normalizer->normalize($target);
        $entry = DictionaryEntry::query()
            ->with('audioMedia')
            ->active()
            ->where('indonesia_normalized', $normalized)
            ->first();

        $matchedField = 'indonesia';

        if ($entry === null) {
            $entry = DictionaryEntry::query()
                ->with('audioMedia')
                ->active()
                ->where('mekongga_normalized', $normalized)
                ->first();
            $matchedField = 'mekongga';
        }

        if ($entry === null && mb_strlen($normalized) >= 4) {
            $entry = DictionaryEntry::query()
                ->with('audioMedia')
                ->active()
                ->where(function ($query) use ($normalized): void {
                    $query->where('indonesia_normalized', 'like', $normalized.'%')
                        ->orWhere('mekongga_normalized', 'like', $normalized.'%');
                })
                ->orderByRaw('CASE WHEN indonesia_normalized LIKE ? THEN 0 ELSE 1 END', [$normalized.'%'])
                ->orderBy('indonesia_normalized')
                ->first();
            $matchedField = $entry?->indonesia_normalized !== null && Str::startsWith($entry->indonesia_normalized, $normalized) ? 'indonesia' : 'mekongga';
        }

        if ($entry === null) {
            return null;
        }

        $word = $matchedField === 'mekongga' ? $entry->mekongga : $entry->indonesia;
        $answer = $matchedField === 'mekongga'
            ? "Dalam Kamus EMI, kata \"{$word}\" berarti \"{$entry->indonesia}\" dalam Bahasa Indonesia."
            : "Dalam Kamus EMI, kata \"{$entry->indonesia}\" memiliki padanan Bahasa Mekongga: \"{$entry->mekongga}\".";

        $source = [
            'id' => $entry->id,
            'title' => 'Kamus EMI',
            'category' => 'Kamus',
            'source_type' => 'dictionary',
            'source_url' => null,
            'dictionary_entry_id' => $entry->id,
        ];

        if ($entry->audio_media_id !== null) {
            $source['audio_media_id'] = $entry->audio_media_id;
        }

        return [
            'answer' => $answer,
            'source' => $source,
            'sources' => [$source],
            'matched' => true,
            'mode' => 'dictionary',
            'provider' => 'dictionary',
            'confidence' => 100,
        ];
    }

    private function target(string $message): ?string
    {
        $normalized = $this->normalizeQuestion($message);

        if (preg_match('/\bbagaimana\s+cara\b/u', $normalized) === 1) {
            return null;
        }

        $patterns = [
            '/\bbahasa\s+mekongga\s+(?:dari|untuk)\s+(.+)$/u',
            '/\barti\s+kata\s+(.+)$/u',
            '/\barti\s+dari\s+(.+)$/u',
            '/\bapa\s+arti\s+(?:kata\s+)?(.+)$/u',
            '/\bpadanan\s+(?:kata\s+)?(.+?)(?:\s+dalam\s+bahasa\s+mekongga)?$/u',
            '/\bterjemahan\s+(.+?)(?:\s+ke\s+bahasa\s+mekongga)?$/u',
            '/\bkata\s+(.+?)\s+dalam\s+bahasa\s+mekongga$/u',
            '/\b(.+?)\s+dalam\s+bahasa\s+mekongga$/u',
            '/\bapa\s+artinya\s+(?:kata\s+)?(.+)$/u',
            '/\bmakna\s+(?:kata\s+)?(.+)$/u',
            '/\byang\s+dimaksud\s+(?:dengan\s+)?(.+)$/u',
            '/\b(.+?)\s+artinya(?:\s+apa)?$/u',
            '/\b(.+?)\s+maksudnya(?:\s+apa)?$/u',
        ];

        foreach ($patterns as $pattern) {
            if (preg_match($pattern, $normalized, $matches) === 1) {
                return $this->cleanTarget($matches[1]);
            }
        }

        return null;
    }

    private function cleanTarget(string $value): ?string
    {
        $words = collect(explode(' ', $this->normalizeQuestion($value)))
            ->reject(fn (string $word): bool => in_array($word, self::GENERIC_WORDS, true))
            ->values();

        if ($words->isEmpty() || $words->count() > 4) {
            return null;
        }

        return $words->implode(' ');
    }

    private function normalizeQuestion(string $value): string
    {
        return trim((string) preg_replace('/\s+/u', ' ', (string) preg_replace('/[^\pL\pN\s]+/u', ' ', Str::lower($value))));
    }
}
