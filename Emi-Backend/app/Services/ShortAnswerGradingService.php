<?php

namespace App\Services;

class ShortAnswerGradingService
{
    public function normalize(?string $value): string
    {
        $value = trim((string) $value);

        if (class_exists(\Normalizer::class)) {
            $value = \Normalizer::normalize($value) ?: $value;
        }

        $value = mb_strtolower($value, 'UTF-8');

        return preg_replace('/\s+/u', ' ', $value) ?: '';
    }

    public function grade(?string $answer, string $correct, bool $fuzzy, ?int $threshold): array
    {
        $normalizedAnswer = $this->normalize($answer);
        $normalizedCorrect = $this->normalize($correct);

        if ($normalizedAnswer === '' || $normalizedCorrect === '') {
            return [false, 0.0, $normalizedAnswer];
        }

        if (! $fuzzy) {
            return [$normalizedAnswer === $normalizedCorrect, $normalizedAnswer === $normalizedCorrect ? 100.0 : 0.0, $normalizedAnswer];
        }

        $maxLength = max(mb_strlen($normalizedAnswer), mb_strlen($normalizedCorrect));
        $distance = levenshtein($normalizedAnswer, $normalizedCorrect);
        $similarity = $maxLength > 0 ? max(0, min(100, (1 - ($distance / $maxLength)) * 100)) : 0;

        return [$similarity >= ($threshold ?? (int) config('quiz.default_fuzzy_threshold')), round($similarity, 2), $normalizedAnswer];
    }
}
