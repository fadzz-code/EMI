<?php

namespace App\Services\Rag;

use App\Services\Ai\GeminiAnswerProvider;
use App\Services\Rag\VectorChunkRetriever;
use Exception;

class RagChatService
{
    protected VectorChunkRetriever $retriever;
    protected GeminiAnswerProvider $answerProvider;

    public function __construct(
        VectorChunkRetriever $retriever, 
        GeminiAnswerProvider $answerProvider
    ) {
        $this->retriever = $retriever;
        $this->answerProvider = $answerProvider;
    }

    /**
     * Memproses pertanyaan chat dan menentukan sumber jawaban (Lokal vs Google Search).
     *
     * @param string $prompt Pertanyaan dari Student
     * @return array Mengembalikan array berisi jawaban dan sumbernya
     */
    public function handleChat(string $prompt): array
    {
        // 1. Cari jawaban di dokumen lokal (Vector Search)
        $localContext = $this->retriever->retrieve($prompt);

        $answer = '';
        $sourceUsed = '';

        if (!empty($localContext)) {
            // 2A. JIKA MATCH LOKAL DITEMUKAN:
            // Kirim ke Gemini menggunakan konteks RAG, nonaktifkan Google Search (useSearch = false)
            $answer = $this->answerProvider->generateAnswer($prompt, $localContext, false);
            $sourceUsed = 'local_document';
        } else {
            // 2B. JIKA MATCH LOKAL KOSONG (FALLBACK):
            // Kirim ke Gemini tanpa konteks, aktifkan Google Search Grounding (useSearch = true)
            $answer = $this->answerProvider->generateAnswer($prompt, null, true);
            $sourceUsed = 'google_search_internet';
        }

        return [
            'prompt' => $prompt,
            'answer' => $answer,
            'source' => $sourceUsed, // Indikator ini sangat berguna untuk UI di Frontend nanti
        ];
    }
}