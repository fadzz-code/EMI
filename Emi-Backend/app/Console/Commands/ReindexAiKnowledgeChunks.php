<?php

namespace App\Console\Commands;

use App\Models\AiKnowledgeItem;
use App\Services\AiKnowledgeChunkingService;
use App\Services\AiKnowledgeEmbeddingService;
use Illuminate\Console\Command;

class ReindexAiKnowledgeChunks extends Command
{
    protected $signature = 'ai:knowledge:reindex {--embed : Generate embeddings after rebuilding chunks}';

    protected $description = 'Rebuild Basis AI knowledge chunks for all knowledge items.';

    public function handle(AiKnowledgeChunkingService $chunkingService, AiKnowledgeEmbeddingService $embeddingService): int
    {
        $processed = 0;
        $chunks = 0;
        $embeddingSucceeded = 0;
        $embeddingSkipped = 0;
        $embeddingFailed = 0;
        $shouldEmbed = (bool) $this->option('embed');
        $canEmbed = $shouldEmbed && $embeddingService->vectorStorageAvailable() && $embeddingService->providerAvailable();

        AiKnowledgeItem::query()->orderBy('created_at')->chunkById(100, function ($items) use (&$processed, &$chunks, &$embeddingSucceeded, &$embeddingSkipped, &$embeddingFailed, $chunkingService, $embeddingService, $canEmbed): void {
            foreach ($items as $item) {
                $chunks += $chunkingService->rebuild($item);
                $processed++;

                if ($canEmbed) {
                    $item->refresh()->chunks()->orderBy('chunk_index')->get()->each(function ($chunk) use (&$embeddingSucceeded, &$embeddingSkipped, &$embeddingFailed, $embeddingService): void {
                        $result = $embeddingService->embed($chunk);

                        match ($result['status']) {
                            'skipped' => $embeddingSkipped++,
                            'succeeded' => $embeddingSucceeded++,
                            default => $embeddingFailed++,
                        };
                    });
                }
            }
        });

        $this->info("Basis AI reindex selesai. Item diproses: {$processed}. Chunk dibuat: {$chunks}.");

        if ($shouldEmbed) {
            if (! $canEmbed) {
                $this->warn('Embedding dilewati karena provider embedding atau kolom vector belum tersedia.');
            } else {
                $this->line("Embedding selesai. Berhasil: {$embeddingSucceeded}. Dilewati: {$embeddingSkipped}. Gagal: {$embeddingFailed}.");
            }
        }

        return self::SUCCESS;
    }
}
