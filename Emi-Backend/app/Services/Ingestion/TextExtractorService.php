<?php

namespace App\Services\Ingestion;

use App\Models\AiKnowledgeItem;
use Spatie\PdfToText\Pdf;
use PhpOffice\PhpWord\IOFactory;
use Exception;
use Illuminate\Support\Facades\Storage;

class TextExtractorService
{
    /**
     * Mengekstrak teks dari berbagai format dokumen.
     */
    public function extract(AiKnowledgeItem $item): string
    {
        $fullPath = Storage::disk('local')->path($item->source_path);

        if (!file_exists($fullPath)) {
            throw new Exception("File fisik tidak ditemukan di path: " . $fullPath);
        }

        // Ambil ekstensi file (pdf, txt, docx)
        $extension = strtolower(pathinfo($fullPath, PATHINFO_EXTENSION));

        if ($extension === 'pdf') {
            $binPath = config('services.pdftotext.binary_path');

            $text = (new Pdf($binPath ?: null))
                ->setPdf($fullPath)
                ->text();

            $text = preg_replace('/[\x00-\x1F\x7F]/u', ' ', $text);
            $text = preg_replace('/\s+/', ' ', $text);

            return trim($text);
        }

        if ($extension === 'txt') {
            return file_get_contents($fullPath);
        }

        if ($extension === 'docx') {
            // MENGGUNAKAN PHPWORD UNTUK MEMBACA FILE .DOCX
            $phpWord = IOFactory::load($fullPath);
            $text = '';

            foreach ($phpWord->getSections() as $section) {
                foreach ($section->getElements() as $element) {
                    // Ambil teks dari paragraf biasa
                    if (method_exists($element, 'getText')) {
                        $text .= $element->getText() . "\n";
                    } 
                    // Ambil teks jika ada di dalam tabel
                    elseif (method_exists($element, 'getRows')) {
                        foreach ($element->getRows() as $row) {
                            foreach ($row->getCells() as $cell) {
                                foreach ($cell->getElements() as $cellElement) {
                                    if (method_exists($cellElement, 'getText')) {
                                        $text .= $cellElement->getText() . " ";
                                    }
                                }
                            }
                            $text .= "\n";
                        }
                    }
                }
            }

            // Bersihkan teks dari karakter kontrol
            $text = preg_replace('/[\x00-\x1F\x7F]/u', ' ', $text);
            $text = preg_replace('/\s+/', ' ', $text);

            return trim($text);
        }

        throw new Exception("Format dokumen tidak didukung untuk diekstrak: " . $extension);
    }
}