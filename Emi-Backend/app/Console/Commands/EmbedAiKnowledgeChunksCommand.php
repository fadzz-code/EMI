<?php

namespace App\Console\Commands;

use App\Models\AiKnowledgeChunk;
use App\Services\AiKnowledgeEmbeddingService;
use Illuminate\Console\Command;

class EmbedAiKnowledgeChunksCommand extends Command
{
    protected $signature = 'ai:knowledge:embed {--force : Regenerate unchanged embeddings} {--limit= : Limit processed chunks}';

    protected $description = 'Generate and store embeddings for Basis AI knowledge chunks.';

    public function handle(AiKnowledgeEmbeddingService $embeddingService): int
    {
        $this->info('Embedding Basis AI EMI');

        if (! $embeddingService->vectorStorageAvailable()) {
            $this->warn('Kolom embedding belum tersedia. Jalankan migration pada PostgreSQL dengan pgvector aktif.');

            return self::SUCCESS;
        }

        if (! $embeddingService->providerAvailable()) {
            $this->warn('Provider embedding belum dikonfigurasi atau API key belum tersedia.');

            return self::SUCCESS;
        }

        $processed = 0;
        $skipped = 0;
        $succeeded = 0;
        $failed = 0;
        $limit = $this->option('limit') !== null ? max(0, (int) $this->option('limit')) : null;
        $force = (bool) $this->option('force');

        $query = AiKnowledgeChunk::query()->orderBy('created_at')->orderBy('id');

        if ($limit !== null) {
            $query->limit($limit);
        }

        $query->get()->each(function (AiKnowledgeChunk $chunk) use (&$processed, &$skipped, &$succeeded, &$failed, $embeddingService, $force): void {
            $processed++;
            $result = $embeddingService->embed($chunk, $force);

            match ($result['status']) {
                'skipped' => $skipped++,
                'succeeded' => $succeeded++,
                default => $failed++,
            };
        });

        $this->line("- Chunk diproses: {$processed}");
        $this->line("- Berhasil: {$succeeded}");
        $this->line("- Dilewati: {$skipped}");
        $this->line("- Gagal: {$failed}");

        return self::SUCCESS;
    }
}
