<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Throwable;

class AiVectorDoctorCommand extends Command
{
    protected $signature = 'ai:vector:doctor';

    protected $description = 'Check EMI Vector RAG readiness for pgvector-based semantic retrieval.';

    public function handle(): int
    {
        $this->info('Pemeriksaan Vector RAG EMI');
        $this->newLine();

        try {
            $defaultConnection = (string) config('database.default');
            $connectionConfig = config("database.connections.{$defaultConnection}", []);
            $driver = (string) ($connectionConfig['driver'] ?? 'unknown');

            $this->line('Koneksi Database');
            $this->line("- Koneksi default: {$defaultConnection}");
            $this->line("- Driver database: {$driver}");
            $this->line('- PostgreSQL: '.($driver === 'pgsql' ? 'ya' : 'tidak'));
            $this->newLine();

            if ($driver !== 'pgsql') {
                $this->line('Status pgvector');
                $this->warn('- Vector retrieval membutuhkan PostgreSQL + pgvector.');
                $this->newLine();
                $this->writeEmbeddingConfig();
                $this->line('Rekomendasi');
                $this->warn('- Gunakan dictionary + keyword retrieval sampai PostgreSQL + pgvector tersedia.');

                return self::SUCCESS;
            }

            $connection = DB::connection($defaultConnection);
            $version = $connection->selectOne('select version() as version');
            $available = $connection->selectOne("select exists (select 1 from pg_available_extensions where name = 'vector') as available");
            $installed = $connection->selectOne("select exists (select 1 from pg_extension where extname = 'vector') as installed");

            $isAvailable = (bool) ($available->available ?? false);
            $isInstalled = (bool) ($installed->installed ?? false);

            $this->line('- Koneksi PostgreSQL: berhasil');
            $this->line('- Versi PostgreSQL: '.($version->version ?? 'tidak diketahui'));
            $this->newLine();

            $this->line('Status pgvector');
            $this->line('- Extension vector tersedia: '.($isAvailable ? 'ya' : 'tidak'));
            $this->line('- Extension vector aktif: '.($isInstalled ? 'ya' : 'tidak'));
            $this->newLine();

            $this->writeEmbeddingConfig();
            $this->line('Rekomendasi');

            if ($isAvailable && $isInstalled) {
                $this->info('- READY untuk migrasi vector di batch berikutnya.');
            } elseif ($isAvailable) {
                $this->warn('- pgvector tersedia tetapi belum aktif. Jalankan CREATE EXTENSION IF NOT EXISTS vector melalui migration terkontrol di batch berikutnya.');
            } else {
                $this->warn('- pgvector belum terpasang di server PostgreSQL. Tetap gunakan dictionary + keyword retrieval sampai pgvector tersedia.');
            }

            return self::SUCCESS;
        } catch (Throwable $exception) {
            $this->error('Pemeriksaan gagal.');
            $this->error('- '.$exception->getMessage());

            return self::FAILURE;
        }
    }

    private function writeEmbeddingConfig(): void
    {
        $this->line('Konfigurasi Embedding');
        $this->line('- Provider embedding: '.config('ai.embedding.provider', 'none'));
        $this->line('- Model embedding: '.config('ai.embedding.model', 'gemini-embedding-001'));
        $this->line('- Dimensi embedding: '.config('ai.embedding.dimensions', 768));
        $this->line('- Vector retrieval: '.(config('ai.vector_retrieval.enabled', false) ? 'aktif' : 'nonaktif'));
        $this->newLine();
    }
}
