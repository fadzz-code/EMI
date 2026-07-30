<?php

namespace App\Jobs;

use App\Models\AiKnowledgeItem;
use App\Services\Ingestion\TextExtractorService;
use App\Services\Ingestion\TextChunkerService;
use App\Services\Ai\GeminiEmbeddingProvider;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Exception;

class ProcessIngestionJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    // Timeout job 5 menit (karena file besar butuh waktu lama untuk embedding)
    public $timeout = 300; 

    protected AiKnowledgeItem $item;

    public function __construct(AiKnowledgeItem $item)
    {
        $this->item = $item;
    }

    public function handle(
        TextExtractorService $extractor,
        TextChunkerService $chunker,
        GeminiEmbeddingProvider $embedder
    ): void {
        try {
            // 1. Update status menjadi processing
            $this->item->update(['status' => 'processing']);

            // 2. Ekstrak teks dari file/URL
            $fullText = $extractor->extract($this->item);

            // 3. Potong teks (Chunking)
            $chunks = $chunker->chunkText($fullText, 800, 150);

            // 4. Proses Embedding & Insert ke Vector DB
            foreach ($chunks as $chunkText) {
                // Jangan proses chunk yang terlalu pendek (misal sisa potongan akhir < 10 karakter)
                if (mb_strlen(trim($chunkText)) < 10) continue;

                // Dapatkan array float 768-d dari Gemini
                $vectorArray = $embedder->embedText($chunkText);
                
                if (empty($vectorArray)) continue;

                // Format array PHP ke format JSON array string untuk input pgvector "[0.1, 0.2, ...]"
                $vectorString = json_encode($vectorArray);

                // Eksekusi Raw SQL menggunakan DB::statement.
                // Penggunaan ?::vector akan memberi tahu PostgreSQL untuk melakukan casting otomatis.
                DB::statement(
                    "INSERT INTO ai_knowledge_chunks (ai_knowledge_item_id, chunk_text, embedding, created_at, updated_at) 
                     VALUES (?, ?, ?::vector, NOW(), NOW())",
                    [$this->item->id, $chunkText, $vectorString]
                );
            }

            // 5. Tandai selesai
            $this->item->update(['status' => 'completed']);

        } catch (Exception $e) {
            // Tandai gagal dan log errornya untuk keperluan debugging
            $this->item->update(['status' => 'failed']);
            Log::error('Ingestion Job Failed: ' . $e->getMessage(), [
                'item_id' => $this->item->id
            ]);
        }
    }
}