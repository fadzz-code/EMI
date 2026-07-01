<?php

namespace App\Services;

use DOMDocument;
use DOMXPath;
use Exception;
use Illuminate\Support\Facades\Http;
use Smalot\PdfParser\Parser;

class AiSourceIngestionService
{
    private const MAX_CONTENT_LENGTH = 50000;

    private const TIMEOUT_SECONDS = 5;

    public function extract(string $type, string $url): array
    {
        $this->validateUrlSecurity($url);

        if ($type === 'link') {
            return $this->extractFromLink($url);
        }

        if ($type === 'pdf') {
            return $this->extractFromPdf($url);
        }

        throw new Exception('Format sumber tidak didukung.');
    }

    private function validateUrlSecurity(string $url): void
    {
        $parsed = parse_url($url);

        if (! isset($parsed['host']) || ! isset($parsed['scheme'])) {
            throw new Exception('URL tidak valid.');
        }

        if (! in_array(strtolower($parsed['scheme']), ['http', 'https'])) {
            throw new Exception('Hanya URL HTTP/HTTPS yang diizinkan.');
        }

        $host = $parsed['host'];

        if (in_array(strtolower($host), ['localhost', '127.0.0.1', '0.0.0.0', '::1'])) {
            throw new Exception('URL tidak valid.');
        }

        $ip = gethostbyname($host);

        if ($this->isPrivateIp($ip)) {
            throw new Exception('URL tidak valid.');
        }
    }

    private function isPrivateIp(string $ip): bool
    {
        if (! filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
            return false;
        }

        $parts = explode('.', $ip);

        if ($parts[0] === '10') {
            return true;
        }

        if ($parts[0] === '172' && $parts[1] >= 16 && $parts[1] <= 31) {
            return true;
        }

        if ($parts[0] === '192' && $parts[1] === '168') {
            return true;
        }

        if ($parts[0] === '169' && $parts[1] === '254') {
            return true;
        }

        if ($parts[0] === '127') {
            return true;
        }

        return false;
    }

    private function extractFromLink(string $url): array
    {
        $response = Http::timeout(self::TIMEOUT_SECONDS)
            ->withUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36')
            ->get($url);

        if (! $response->successful()) {
            throw new Exception('Gagal mengunduh halaman: HTTP '.$response->status());
        }

        $html = $response->body();

        if (empty(trim($html))) {
            throw new Exception('Halaman kosong.');
        }

        $dom = new DOMDocument;
        libxml_use_internal_errors(true);
        if (! str_contains(strtolower($html), 'charset')) {
            $html = '<meta http-equiv="Content-Type" content="text/html; charset=utf-8">'.$html;
        }
        $dom->loadHTML($html);
        libxml_clear_errors();

        $xpath = new DOMXPath($dom);

        $unwanted = $xpath->query('//script | //style | //nav | //footer | //header | //aside | //noscript | //iframe | //svg');
        foreach ($unwanted as $element) {
            $element->parentNode->removeChild($element);
        }

        $nodes = $xpath->query('//article');
        if ($nodes->length === 0) {
            $nodes = $xpath->query('//main');
        }
        if ($nodes->length === 0) {
            $nodes = $xpath->query('//div[contains(@class, "content") or contains(@class, "post") or contains(@class, "article")]');
        }
        if ($nodes->length === 0) {
            $nodes = $xpath->query('//body');
        }

        $content = '';
        if ($nodes->length > 0) {
            foreach ($nodes as $node) {
                $content .= $node->textContent."\n";
            }
        }

        $cleanText = $this->cleanText($content);

        if (empty($cleanText)) {
            throw new Exception('Tidak ada teks yang dapat dibaca di halaman ini.');
        }

        $titleNode = $xpath->query('//title')->item(0);
        $title = $titleNode ? trim($titleNode->textContent) : null;

        return [
            'content' => mb_substr($cleanText, 0, self::MAX_CONTENT_LENGTH),
            'title' => $title,
            'source_type' => 'link',
            'source_url' => $url,
            'character_count' => mb_strlen($cleanText),
            'warnings' => [],
        ];
    }

    private function extractFromPdf(string $url): array
    {
        $response = Http::timeout(self::TIMEOUT_SECONDS)
            ->withUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36')
            ->get($url);

        if (! $response->successful()) {
            throw new Exception('Gagal mengunduh PDF: HTTP '.$response->status());
        }

        $pdfContent = $response->body();

        if (strpos($pdfContent, '%PDF') !== 0) {
            throw new Exception('File bukan PDF yang valid.');
        }

        if (strlen($pdfContent) > 5 * 1024 * 1024) {
            throw new Exception('Ukuran PDF terlalu besar (Maks 5MB).');
        }

        $parser = new Parser;
        $pdf = $parser->parseContent($pdfContent);

        $text = $pdf->getText();
        $cleanText = $this->cleanText($text);

        $warnings = [];
        if (empty($cleanText)) {
            $warnings[] = 'PDF mungkin berupa hasil scan/gambar sehingga teks tidak dapat dibaca otomatis.';
            throw new Exception('PDF harus berupa dokumen berbasis teks dari URL publik. PDF hasil scan/foto belum dapat dibaca otomatis.');
        }

        $details = $pdf->getDetails();
        $title = $details['Title'] ?? null;
        if ($title === 'Untitled' || empty(trim($title))) {
            $title = null;
        }

        return [
            'content' => mb_substr($cleanText, 0, self::MAX_CONTENT_LENGTH),
            'title' => $title,
            'source_type' => 'pdf',
            'source_url' => $url,
            'character_count' => mb_strlen($cleanText),
            'warnings' => $warnings,
        ];
    }

    private function cleanText(string $text): string
    {
        $text = preg_replace("/[ \t]+/", ' ', $text);
        $text = preg_replace("/\n\s+/", "\n", $text);
        $text = preg_replace("/\n{3,}/", "\n\n", $text);

        return trim($text);
    }
}
