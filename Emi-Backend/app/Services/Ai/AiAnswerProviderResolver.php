<?php

namespace App\Services\Ai;

class AiAnswerProviderResolver
{
    public function resolve(): AiAnswerProviderInterface
    {
        $provider = (string) config('ai.free_provider', 'none');

        if ($provider === 'none' || $provider === '') {
            return new NullAiAnswerProvider('free_ai_disabled');
        }

        return new FreeAiAnswerProvider(
            provider: $provider,
            apiKey: config('ai.free_api_key'),
            model: config('ai.free_model'),
            timeoutSeconds: max(1, (int) config('ai.free_timeout_seconds', 8)),
        );
    }
}
