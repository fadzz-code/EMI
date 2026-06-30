<?php

namespace App\Services\Ai;

class AiAnswerResult
{
    public function __construct(
        public readonly bool $success,
        public readonly ?string $answer = null,
        public readonly string $mode = 'default_extractive',
        public readonly string $provider = 'default',
        public readonly ?string $fallbackReason = null,
        public readonly ?string $prompt = null,
    ) {}

    public static function success(string $answer, string $provider, ?string $prompt = null): self
    {
        return new self(true, $answer, 'free_ai', $provider, null, $prompt);
    }

    public static function fallback(string $reason): self
    {
        return new self(false, null, 'default_extractive', 'default', $reason);
    }
}
