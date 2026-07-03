<?php

namespace App\Services\Ai;

interface EmbeddingProviderInterface
{
    public function isAvailable(): bool;

    public function embedDocument(string $text): EmbeddingResult;

    public function embedQuery(string $text): EmbeddingResult;
}
