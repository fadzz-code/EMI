<?php

namespace App\Services\Ai;

class EmbeddingResult
{
    public function __construct(
        public readonly bool $success,
        public readonly array $vector = [],
        public readonly string $provider = 'none',
        public readonly ?string $model = null,
        public readonly int $dimensions = 0,
        public readonly string $inputType = 'document',
        public readonly ?string $error = null,
        public readonly array $metadata = [],
    ) {}

    public static function success(array $vector, string $provider, ?string $model, int $dimensions, string $inputType, array $metadata = []): self
    {
        return new self(true, array_map('floatval', $vector), $provider, $model, $dimensions, $inputType, null, $metadata);
    }

    public static function failure(string $error, string $provider = 'none', ?string $model = null, int $dimensions = 0, string $inputType = 'document', array $metadata = []): self
    {
        return new self(false, [], $provider, $model, $dimensions, $inputType, $error, $metadata);
    }
}
