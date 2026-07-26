<?php

namespace App\Services\Ai;

use App\Models\AiKnowledgeItem;

interface AiAnswerProviderInterface
{
    public function generateAnswer(string $question, ?AiKnowledgeItem $reference, array $chunks = []): AiAnswerResult;
}
