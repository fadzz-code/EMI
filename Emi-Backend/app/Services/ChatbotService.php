<?php

namespace App\Services;

use App\Models\AiKnowledgeItem;
use App\Models\User;
use App\Services\Ai\AiAnswerProviderResolver;

class ChatbotService
{
    private const TOP_K = 3;

    public function __construct(
        private readonly DefaultExtractiveAnswerProvider $defaultProvider,
        private readonly AiAnswerProviderResolver $providerResolver,
        private readonly AiKnowledgeChunkingService $chunkingService,
        private readonly DictionaryRetriever $dictionaryRetriever,
        private readonly VectorChunkRetriever $vectorChunkRetriever,
        private readonly KeywordChunkRetriever $keywordChunkRetriever,
    ) {}

    public function respond(User $student, string $message): array
    {
        $dictionaryMatch = $this->dictionaryRetriever->retrieve($message);

        if ($dictionaryMatch !== null) {
            return $dictionaryMatch;
        }

        $match = $this->findBestPublishedReferences($message);

        if ($match === null) {
            return $this->defaultProvider->answer(null, $message);
        }

        $providerResult = $this->providerResolver->resolve()->generateAnswer($message, $match['item'], $match['chunks']);

        if ($providerResult->success && $providerResult->answer) {
            return $this->defaultProvider->answerFromProvider(
                $match['item'],
                $providerResult->answer,
                $providerResult->mode,
                $providerResult->provider,
                $match['confidence'],
                $match['chunks'],
            );
        }

        return $this->defaultProvider->answerFromChunks(
            $match['chunks'],
            $message,
            $match['confidence'],
            $match['keywords'],
            $providerResult->fallbackReason,
        );
    }

    private function findBestPublishedReferences(string $message): ?array
    {
        AiKnowledgeItem::query()
            ->published()
            ->doesntHave('chunks')
            ->get()
            ->each(fn (AiKnowledgeItem $item) => $this->chunkingService->rebuild($item));

        $vectorMatches = (bool) config('ai.vector_retrieval.enabled', false)
            ? $this->vectorChunkRetriever->retrieve($message)
            : [];
        $keywordMatches = $this->keywordChunkRetriever->retrieve($message);
        $matches = collect([...$vectorMatches, ...$keywordMatches])
            ->unique(fn (array $result): string => (string) $result['chunk']->id)
            ->sortByDesc(fn (array $result): int|float => $result['retrieval_mode'] === 'vector'
                ? ($result['similarity_score'] ?? 0) * 100
                : $result['confidence'])
            ->take(self::TOP_K)
            ->values();

        if ($matches->isEmpty()) {
            return null;
        }

        $best = $matches->first();
        $keywords = $this->keywordChunkRetriever->keywords($message);

        return [
            'item' => $best['item'],
            'confidence' => $best['confidence'],
            'keywords' => $keywords,
            'chunks' => $matches->all(),
        ];
    }
}
