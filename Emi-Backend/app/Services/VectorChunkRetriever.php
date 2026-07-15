<?php

namespace App\Services;

use App\Models\AiKnowledgeChunk;
use App\Services\Ai\EmbeddingProviderResolver;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Throwable;

class VectorChunkRetriever
{
    public function __construct(private readonly EmbeddingProviderResolver $resolver) {}

    public function retrieve(string $message): array
    {
        if (! $this->available()) {
            return [];
        }

        try {
            $provider = $this->resolver->resolve();
            $embedding = $provider->embedQuery($message);

            if (! $embedding->success || $embedding->vector === []) {
                return [];
            }

            $vector = $this->vectorString($embedding->vector);
            $limit = max(1, (int) config('ai.vector_retrieval.top_k', 5));
            $rows = DB::select(
                'select c.id, c.embedding <=> ?::vector as distance
                from ai_knowledge_chunks c
                inner join ai_knowledge_items i on i.id = c.ai_knowledge_item_id
                where c.embedding is not null
                    and i.status = ?
                    and i.deleted_at is null
                    and (c.metadata is null or c.metadata->>\'searchable\' is distinct from \'false\')
                    and (c.metadata is null or coalesce(c.metadata->>\'page_type\', \'body\') not in (\'table_of_contents\', \'front_matter\', \'copyright\', \'bibliography\', \'cover\', \'low_quality_ocr\'))
                order by c.embedding <=> ?::vector
                limit ?',
                [$vector, 'published', $vector, $limit]
            );

            if ($rows === []) {
                return [];
            }

            $distances = collect($rows)->mapWithKeys(fn (object $row): array => [(string) $row->id => (float) $row->distance]);

            return AiKnowledgeChunk::query()
                ->with('knowledgeItem')
                ->whereIn('id', $distances->keys()->all())
                ->get()
                ->sortBy(fn (AiKnowledgeChunk $chunk): int => $distances->keys()->search($chunk->id))
                ->map(function (AiKnowledgeChunk $chunk) use ($distances): array {
                    $distance = $distances[$chunk->id] ?? 1.0;

                    return [
                        'item' => $chunk->knowledgeItem,
                        'chunk' => $chunk,
                        'confidence' => (int) round(max(0, 1 - $distance) * 100),
                        'keywords' => collect(),
                        'retrieval_mode' => 'vector',
                        'distance' => $distance,
                        'similarity_score' => max(0, 1 - $distance),
                    ];
                })
                ->filter(fn (array $result): bool => $result['item'] !== null && $result['item']->status === 'published' && $result['item']->isReadyForPublication())
                ->values()
                ->all();
        } catch (Throwable) {
            return [];
        }
    }

    public function available(): bool
    {
        if (! (bool) config('ai.vector_retrieval.enabled', false)) {
            return false;
        }

        try {
            if (DB::getDriverName() !== 'pgsql' || ! Schema::hasColumn('ai_knowledge_chunks', 'embedding')) {
                return false;
            }

            $installed = DB::selectOne("select exists (select 1 from pg_extension where extname = 'vector') as installed");

            return (bool) ($installed->installed ?? false) && $this->resolver->resolve()->isAvailable();
        } catch (Throwable) {
            return false;
        }
    }

    private function vectorString(array $vector): string
    {
        return '['.implode(',', array_map(fn (float $value): string => rtrim(rtrim(sprintf('%.10F', $value), '0'), '.'), array_map('floatval', $vector))).']';
    }
}
