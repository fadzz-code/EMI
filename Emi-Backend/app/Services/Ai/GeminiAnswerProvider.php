<?php

namespace App\Services\Ai;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Exception;

class GeminiAnswerProvider
{
    protected string $apiKey;

    // Daftar model alternatif (Auto-Switch) seperti referensi Anda
    // Daftar model alternatif (Auto-Switch) sesuai ketersediaan dari API Key baru Anda
    protected array $models = [
        'gemini-2.5-flash',         // Pilihan utama: Versi stabil, cerdas, dan cepat
        'gemini-2.0-flash',         // Cadangan 1: Sangat stabil
        'gemini-flash-lite-latest'  // Cadangan 2: Paling ringan, aman dari limit
    ];

    public function __construct()
    {
        $this->apiKey = config('services.gemini.api_key') ?? env('GEMINI_API_KEY');
    }

    /**
     * Menghasilkan jawaban berdasarkan prompt dan konteks (RAG)
     */
    public function generateAnswer(string $prompt, ?string $localContext = null, bool $useSearch = true): string
    {
        // 1. Susun Teks Konteks (Jika ada)
        $contextText = "";
        if (!empty($localContext)) {
            $contextText = "\n\n--- DOKUMEN KNOWLEDGE BASE LOKAL ---\n" .
                $localContext . "\n" .
                "--- AKHIR DOKUMEN ---\n" .
                "Gunakan dokumen lokal di atas sebagai referensi UTAMA untuk menjawab pertanyaan.";
        }

        $finalUserPrompt = $prompt . $contextText;

        // 2. Susun Payload (Meniru struktur solid dari referensi Anda)
        $payload = [
            'systemInstruction' => [
                'parts' => [['text' => $this->getSystemInstruction()]]
            ],
            'contents' => [
                [
                    'role' => 'user',
                    'parts' => [['text' => $finalUserPrompt]]
                ]
            ],
            'generationConfig' => [
                'temperature' => 0.4,
                'maxOutputTokens' => 1024,
            ]
        ];

        // 3. Konfigurasi Google Search Grounding (Perbaikan Syntax)
        $useSearch = false;
        if ($useSearch) {
            $payload['tools'] = [
                ['googleSearch' => (object)[]] // Penulisan yang benar sesuai referensi Anda
            ];
        }

        $lastExceptionMessage = '';

        // 4. Mekanisme Auto-Switch Model
        foreach ($this->models as $selectedModel) {
            $url = "https://generativelanguage.googleapis.com/v1beta/models/{$selectedModel}:generateContent?key={$this->apiKey}";

            try {
                $response = Http::withHeaders(['Content-Type' => 'application/json'])
                    ->withOptions([
                        'verify' => false, // Abaikan SSL lokal Windows yang sering bermasalah
                        'curl' => [
                            CURLOPT_IPRESOLVE => CURL_IPRESOLVE_V4, // Paksa gunakan koneksi IPv4
                        ]
                    ])
                    ->timeout(120) // Beri waktu tunggu lebih lama jika internet lambat
                    ->post($url, $payload);

                // Jika sukses (HTTP 200), ambil jawaban dan hentikan loop
                if ($response->successful()) {
                    $result = $response->json();
                    return $result['candidates'][0]['content']['parts'][0]['text'] ?? 'Maaf, saya tidak dapat memproses jawaban saat ini.';
                }

                // Catat jika gagal dan coba model berikutnya
                $lastExceptionMessage = $response->body();
                Log::warning("Model {$selectedModel} Gagal: " . $lastExceptionMessage);
            } catch (Exception $e) {
                $lastExceptionMessage = $e->getMessage();
                Log::warning("Model {$selectedModel} Error Jaringan: " . $lastExceptionMessage);
            }
        }

        // 5. Jika semua model gagal
        throw new Exception("Gemini Chat API Error (Semua Model Gagal): " . $lastExceptionMessage);
    }

    /**
     * Instruksi sistem agar AI menjawab dengan karakter EMI Bot
     */
    protected function getSystemInstruction(): string
    {
        return <<<TEXT
Anda adalah "AIBot Mekongga", asisten virtual pintar dan pemandu resmi Layanan Informasi Daerah Mekongga.
Aturan Utama:
1. Bersikaplah ramah, akademis, namun tetap santai dan responsif.
2. Jawab pertanyaan user secara jelas, padat, dan terstruktur.
3. Jika terdapat "DOKUMEN KNOWLEDGE BASE LOKAL", prioritaskan jawaban 100% berdasarkan informasi dari dokumen tersebut.
4. Jika pertanyaan di luar konteks dokumen lokal, gunakan pengetahuan umum atau pencarian web dengan jujur.
5. Gunakan format Markdown (seperti **bold** atau bullet points) agar jawaban mudah dibaca.
6. Jangan gunakan ** ketika mengutip kata, gunakan "
TEXT;
    }
}
