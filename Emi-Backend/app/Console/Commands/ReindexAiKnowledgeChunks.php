<?php

namespace App\Console\Commands;

use App\Models\AiKnowledgeItem;
use App\Services\AiKnowledgeChunkingService;
use Illuminate\Console\Command;

class ReindexAiKnowledgeChunks extends Command
{
    protected $signature = 'ai:knowledge:reindex';

    protected $description = 'Rebuild Basis AI knowledge chunks for all knowledge items.';

    public function handle(AiKnowledgeChunkingService $chunkingService): int
    {
        $processed = 0;
        $chunks = 0;

        AiKnowledgeItem::query()->orderBy('created_at')->chunkById(100, function ($items) use (&$processed, &$chunks, $chunkingService): void {
            foreach ($items as $item) {
                $chunks += $chunkingService->rebuild($item);
                $processed++;
            }
        });

        $this->info("Basis AI reindex selesai. Item diproses: {$processed}. Chunk dibuat: {$chunks}.");

        return self::SUCCESS;
    }
}
