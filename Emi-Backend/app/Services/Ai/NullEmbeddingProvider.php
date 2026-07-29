<?php

namespace App\Services\Ai;

class NullEmbeddingProvider implements EmbeddingProviderInterface
{
    public function __construct(private readonly string $error = 'Provider embedding belum dikonfigurasi.') {}

    public function isAvailable(): bool
    {
        return false;
    }

    public function embedDocument(string $text): EmbeddingResult
    {
        return EmbeddingResult::failure($this->error, inputType: 'document');
    }

    public function embedQuery(string $text): EmbeddingResult
    {
        return EmbeddingResult::failure($this->error, inputType: 'query');
    }
}
