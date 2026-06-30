<?php

namespace App\Services\Ai;

use App\Models\AiKnowledgeItem;

class NullAiAnswerProvider implements AiAnswerProviderInterface
{
    public function __construct(private readonly string $reason = 'free_ai_disabled') {}

    public function generateAnswer(string $question, AiKnowledgeItem $reference): AiAnswerResult
    {
        return AiAnswerResult::fallback($this->reason);
    }
}
