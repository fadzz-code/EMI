<?php

namespace App\Services\Ingestion;

class TextChunkerService
{
    /**
     * Memotong teks menjadi potongan UTF-8 safe dengan overlap.
     * 
     * @param string $text Teks mentah
     * @param int $maxSize Ukuran maksimal karakter per chunk (default 800)
     * @param int $overlap Jumlah karakter tumpang tindih (default 150)
     * @return array<string>
     */
    public function chunkText(string $text, int $maxSize = 800, int $overlap = 150): array
    {
        // Bersihkan spasi berlebih, tab, dan enter bertumpuk
        $text = trim(preg_replace('/\s+/', ' ', $text));
        
        $chunks = [];
        $length = mb_strlen($text, 'UTF-8');
        $start = 0;

        while ($start < $length) {
            $chunk = mb_substr($text, $start, $maxSize, 'UTF-8');
            $chunks[] = $chunk;
            // Maju sesuai maxSize dikurangi overlap agar ada kalimat yang bersambung ke chunk berikutnya
            $start += ($maxSize - $overlap); 
        }

        return $chunks;
    }
}