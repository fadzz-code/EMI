<?php

namespace App\Services;

use Normalizer;

class DictionaryNormalizer
{
    public function normalize(?string $value): string
    {
        $value = trim((string) $value);

        if (class_exists(Normalizer::class)) {
            $value = Normalizer::normalize($value, Normalizer::FORM_C) ?: $value;
        }

        $value = mb_strtolower($value, 'UTF-8');

        return preg_replace('/\s+/u', ' ', $value) ?: '';
    }

    public function normalizeDisplay(?string $value): ?string
    {
        if ($value === null) {
            return null;
        }

        $value = trim($value);
        $value = preg_replace('/\s+/u', ' ', $value) ?: '';

        return $value !== '' ? $value : null;
    }
}
