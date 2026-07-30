<?php

namespace App\Services\Rag;

use App\Services\Ai\GeminiEmbeddingProvider;
use Illuminate\Support\Facades\DB;
use Exception;

class VectorChunkRetriever
{
    protected GeminiEmbeddingProvider $embedder;

    public function __construct(GeminiEmbeddingProvider $embedder)
    {
        $this->embedder = $embedder;
    }

    /**
     * Mencari chunk lokal yang paling relevan dengan prompt.
     * 
     * @param string $prompt Pertanyaan dari user
     * @param int $limit Batas maksimal dokumen yang diambil
     * @param float $similarityThreshold Batas minimal kemiripan (0.0 - 1.0). Default 0.70 (70% mirip)
     * @return string Konteks gabungan dari chunk yang ditemukan, atau string kosong jika tidak ada
     */
    public function retrieve(string $prompt, int $limit = 3, float $similarityThreshold = 0.70): string
    {
        // 1. Ubah pertanyaan menjadi vector (768 dimensi)
        $promptVector = $this->embedder->embedText($prompt);
        
        if (empty($promptVector)) {
            return '';
        }

        // 2. Format ke string JSON agar bisa dibaca oleh PostgreSQL pgvector
        $vectorString = json_encode($promptVector);

        // Operator <=> di pgvector menghitung Cosine Distance (Jarak).
        // Cosine Similarity (Kemiripan) = 1 - Cosine Distance.
        // Jadi, untuk mendapatkan similarity > 0.70, distance-nya harus < 0.30.
        $maxDistance = 1 - $similarityThreshold;

        // 3. Query pencarian vector menggunakan Raw SQL
        // Kita bind $vectorString beberapa kali untuk operasi SELECT, WHERE, dan ORDER BY
        $results = DB::select(
            "SELECT chunk_text, (1 - (embedding <=> ?::vector)) AS similarity 
             FROM ai_knowledge_chunks 
             WHERE (embedding <=> ?::vector) < ? 
             ORDER BY embedding <=> ?::vector ASC 
             LIMIT ?",
            [$vectorString, $vectorString, $maxDistance, $vectorString, $limit]
        );

        if (empty($results)) {
            return '';
        }

        // 4. Gabungkan teks dari chunk-chunk yang ditemukan
        $contextTexts = [];
        foreach ($results as $index => $row) {
            $contextTexts[] = "[Kutipan " . ($index + 1) . "]: " . $row->chunk_text;
        }

        return implode("\n\n", $contextTexts);
    }
}