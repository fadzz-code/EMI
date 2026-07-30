<?php

namespace App\Http\Controllers\Student;

use App\Http\Controllers\Controller;
use App\Services\Rag\RagChatService;
use Illuminate\Http\Request;

class ChatController extends Controller
{
    protected RagChatService $chatService;

    public function __construct(RagChatService $chatService)
    {
        $this->chatService = $chatService;
    }

    /**
     * Endpoint untuk mengirim pertanyaan dan mendapatkan jawaban dari AI.
     */
    public function sendMessage(Request $request)
    {
        $request->validate([
            'prompt' => 'required|string|max:1000',
        ]);

        $prompt = $request->prompt;

        // Panggil Orchestrator RAG dari Fase 4
        // $result akan berisi array: ['prompt', 'answer', 'source']
        $result = $this->chatService->handleChat($prompt);

        // Opsi: Di sini Anda bisa menambahkan logika untuk menyimpan
        // histori chat ke database (misal tabel chat_messages) jika diperlukan.

        return response()->json([
            'status' => 'success',
            'data' => [
                'user_message' => $result['prompt'],
                'ai_response' => $result['answer'],
                'source_used' => $result['source'], // 'local_document' atau 'google_search_internet'
            ]
        ]);
    }

    /**
     * Endpoint untuk mengambil histori chat Student (Opsional/Placeholder)
     */
    public function history(Request $request)
    {
        // Placeholder: Ambil dari database histori chat berdasarkan ID User yang login.
        // Karena di versi refactored tabel chat_messages tidak dibuat di Fase 1, 
        // Anda bisa mengembalikan array kosong sementara atau membuat model histori nanti.
        return response()->json([
            'status' => 'success',
            'data' => [] 
        ]);
    }
}