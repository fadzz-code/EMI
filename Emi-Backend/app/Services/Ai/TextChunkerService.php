<?php

namespace App\Services\Ai;

class TextChunkerService
{
    /**
     * Memotong teks menjadi potongan-potongan (chunks) dengan ukuran tertentu.
     *
     * @param string $text Teks mentah yang akan dipotong.
     * @param int $chunkSize Ukuran target per chunk dalam karakter (default 700).
     * @param int $overlap Karakter yang tumpang tindih antar chunk (default 70).
     * @return array<string> Daftar potongan teks.
     */
    public function chunk(string $text, int $chunkSize = 700, int $overlap = 70): array
    {
        // Normalisasi baris baru dan spasi berlebih
        $cleanText = preg_replace('/\r\n|\r/', "\n", $text);
        $cleanText = preg_replace("/\n{3,}/", "\n\n", $cleanText);
        $cleanText = trim((string) $cleanText);

        if (mb_strlen($cleanText) <= $chunkSize) {
            return [$cleanText];
        }

        $chunks = [];
        $start = 0;
        $totalLength = mb_strlen($cleanText);

        while ($start < $totalLength) {
            $end = $start + $chunkSize;

            if ($end >= $totalLength) {
                $chunk = mb_substr($cleanText, $start);
                $chunks[] = trim($chunk);
                break;
            }

            // Cari titik pemisah terbaik (paragraf > titik/kalimat > spasi)
            $slice = mb_substr($cleanText, $start, $chunkSize);
            $breakPos = $this->findBestBreakPoint($slice);

            if ($breakPos !== false && $breakPos > ($chunkSize * 0.4)) {
                $actualLength = $breakPos;
            } else {
                $actualLength = $chunkSize;
            }

            $chunk = mb_substr($cleanText, $start, $actualLength);
            $trimmedChunk = trim($chunk);

            if (!empty($trimmedChunk)) {
                $chunks[] = $trimmedChunk;
            }

            // Geser titik awal dengan memperhitungkan overlap
            $start += max(1, $actualLength - $overlap);
        }

        return $chunks;
    }

    /**
     * Cari posisi pemisah kalimat atau paragraf terbaik agar potongan alami.
     */
    private function findBestBreakPoint(string $text): int|false
    {
        // Prioritas 1: Pemisah paragraf (\n\n)
        $pos = mb_strrpos($text, "\n\n");
        if ($pos !== false) {
            return $pos + 2;
        }

        // Prioritas 2: Akhir kalimat (. , ! , ?) diikuti spasi atau newline
        if (preg_match_all('/[.!?]\s+/u', $text, $matches, PREG_OFFSET_CAPTURE)) {
            $lastMatch = end($matches[0]);
            return $lastMatch[1] + mb_strlen($lastMatch[0]);
        }

        // Prioritas 3: Spasi antar kata
        $pos = mb_strrpos($text, ' ');
        if ($pos !== false) {
            return $pos + 1;
        }

        return false;
    }
}