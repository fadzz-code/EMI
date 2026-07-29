<?php

namespace App\Services;

use Illuminate\Support\Str;

class AiPdfPageClassifier
{
    public function clean(string $text): string
    {
        $text = preg_replace('/[\x{3130}\x{3164}\x{FFFD}]/u', '', $text);
        $text = preg_replace('/[ \t]+/', ' ', $text);
        $text = preg_replace('/\n\s+/', "\n", $text);
        $text = preg_replace('/-\s*\n\s*/u', '', $text);
        $text = preg_replace('/\n{3,}/', "\n\n", $text);

        return trim($text);
    }

    public function classify(string $text, int $pageNumber): array
    {
        $cleaned = $this->clean($text);
        $normalized = Str::lower($cleaned);
        $lines = collect(preg_split('/\R/u', $cleaned) ?: [])
            ->map(fn (string $line): string => trim($line))
            ->filter()
            ->values();
        $ocrNoiseScore = $this->ocrNoiseScore($cleaned);
        $pageType = 'body';
        $searchable = true;
        $skipReason = null;

        if ($cleaned === '' || mb_strlen($cleaned) < 20) {
            $pageType = 'empty';
            $searchable = false;
            $skipReason = 'Halaman kosong atau terlalu pendek';
        } elseif ($ocrNoiseScore >= 0.45) {
            $pageType = 'low_quality_ocr';
            $searchable = false;
            $skipReason = 'Kualitas teks OCR rendah';
        } elseif ($this->isTableOfContents($normalized, $lines)) {
            $pageType = 'table_of_contents';
            $searchable = false;
            $skipReason = 'Daftar isi';
        } elseif (preg_match('/\b(daftar pustaka|bibliografi|references)\b/u', $normalized)) {
            $pageType = 'bibliography';
            $searchable = false;
            $skipReason = 'Daftar pustaka';
        } elseif ($pageNumber <= 5 && preg_match('/\b(hak cipta|copyright|isbn|penerbit)\b/u', $normalized) && mb_strlen($cleaned) < 1200) {
            $pageType = 'copyright';
            $searchable = false;
            $skipReason = 'Hak cipta';
        } elseif ($pageNumber <= 5 && preg_match('/\b(kata pengantar|ucapan terima kasih|prakata)\b/u', $normalized) && mb_strlen($cleaned) < 1800) {
            $pageType = 'front_matter';
            $searchable = false;
            $skipReason = 'Materi pembuka';
        } elseif ($pageNumber <= 2 && $lines->count() <= 6 && mb_strlen($cleaned) < 300 && mb_strtoupper($cleaned) === $cleaned) {
            $pageType = 'cover';
            $searchable = false;
            $skipReason = 'Sampul';
        }

        return [
            'content' => $cleaned,
            'page_type' => $pageType,
            'searchable' => $searchable,
            'skip_reason' => $skipReason,
            'ocr_noise_score' => $ocrNoiseScore,
        ];
    }

    private function isTableOfContents(string $normalized, $lines): bool
    {
        if (preg_match('/\b(daftar isi|table of contents|contents)\b/u', $normalized)) {
            return true;
        }

        if ($lines->count() < 4) {
            return false;
        }

        $tocLikeLines = $lines->filter(fn (string $line): bool => $this->isTocLine($line))->count();
        $dottedLeaderLines = $lines->filter(fn (string $line): bool => preg_match('/\.{3,}\s*\d+\s*$/u', $line))->count();

        return $dottedLeaderLines >= 3 || ($tocLikeLines >= 5 && ($tocLikeLines / max(1, $lines->count())) >= 0.45);
    }

    private function isTocLine(string $line): bool
    {
        $line = trim($line);

        return (bool) preg_match('/^(bab\s+[ivxlcdm]+|\d+(?:\.\d+)*|[a-z][\w\s,\-]{6,})\s+.{0,90}(\.{2,}\s*)?\d+$/iu', $line);
    }

    private function ocrNoiseScore(string $text): float
    {
        $length = max(1, mb_strlen($text));
        preg_match_all('/[^\pL\pN\s.,;:!?()\-\/]/u', $text, $matches);
        $noise = count($matches[0]);

        return round(min(1, $noise / $length), 2);
    }
}
