<?php

namespace App\Services;

use DOMDocument;
use DOMXPath;
use Exception;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use PhpOffice\PhpWord\IOFactory;
use Smalot\PdfParser\Parser;

class AiSourceIngestionService
{
    private const MAX_CONTENT_LENGTH = 50000;

    private const TIMEOUT_SECONDS = 5;

    private const MAX_REDIRECTS = 3;

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

        if (! in_array(strtolower($parsed['scheme']), ['http', 'https'], true)) {
            throw new Exception('Hanya URL HTTP/HTTPS yang diizinkan.');
        }

        $host = trim($parsed['host'], '[]');
        $lowerHost = strtolower($host);

        if (in_array($lowerHost, ['localhost', 'metadata.google.internal'], true) || str_contains($lowerHost, 'metadata')) {
            throw new Exception('URL tidak valid.');
        }

        foreach ($this->resolveHostIps($host) as $ip) {
            if ($this->isUnsafeIp($ip)) {
                throw new Exception('URL tidak valid.');
            }
        }
    }

    private function resolveHostIps(string $host): array
    {
        $host = trim($host, '[]');

        if (filter_var($host, FILTER_VALIDATE_IP)) {
            return [$host];
        }

        $records = dns_get_record($host, DNS_A + DNS_AAAA) ?: [];
        $ips = collect($records)
            ->map(fn (array $record): ?string => $record['ip'] ?? $record['ipv6'] ?? null)
            ->filter()
            ->values()
            ->all();

        $fallback = gethostbynamel($host) ?: [];

        return array_values(array_unique([...$ips, ...$fallback]));
    }

    private function isUnsafeIp(string $ip): bool
    {
        if (str_starts_with($ip, '::ffff:')) {
            $mapped = substr($ip, 7);

            return $this->isUnsafeIp($mapped);
        }

        if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4)) {
            return ! filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4 | FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE)
                || str_starts_with($ip, '100.')
                || str_starts_with($ip, '169.254.')
                || $ip === '255.255.255.255';
        }

        if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV6)) {
            $lower = strtolower($ip);

            return ! filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV6 | FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE)
                || $lower === '::'
                || str_starts_with($lower, 'fe80:')
                || str_starts_with($lower, 'fc')
                || str_starts_with($lower, 'fd')
                || str_starts_with($lower, 'ff');
        }

        return true;
    }

    private function guardedGet(string $url)
    {
        $current = $url;

        for ($redirects = 0; $redirects <= self::MAX_REDIRECTS; $redirects++) {
            $this->validateUrlSecurity($current);
            $response = Http::timeout(self::TIMEOUT_SECONDS)
                ->withoutRedirecting()
                ->withUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36')
                ->get($current);

            if (! $response->redirect()) {
                return $response;
            }

            $location = $response->header('Location');
            if (! is_string($location) || $location === '') {
                throw new Exception('Redirect sumber tidak valid.');
            }

            $current = $this->absoluteUrl($current, $location);
        }

        throw new Exception('Terlalu banyak redirect.');
    }

    private function absoluteUrl(string $base, string $location): string
    {
        if (parse_url($location, PHP_URL_SCHEME) !== null) {
            return $location;
        }

        $parts = parse_url($base);
        $scheme = $parts['scheme'] ?? 'https';
        $host = $parts['host'] ?? '';
        $port = isset($parts['port']) ? ':'.$parts['port'] : '';

        return $scheme.'://'.$host.$port.'/'.ltrim($location, '/');
    }

    private function extractFromLink(string $url): array
    {
        $response = $this->guardedGet($url);

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

    public function extractFromPdfUpload(UploadedFile $file): array
    {
        $pdfContent = file_get_contents($file->getRealPath());
        $title = pathinfo($file->getClientOriginalName(), PATHINFO_FILENAME);
        $extracted = $this->parsePdfContent($pdfContent, $title, 'PDF tidak memiliki teks yang dapat dibaca. PDF hasil scan/foto belum didukung.');
        $filename = Str::uuid().'.pdf';
        $path = $file->storeAs('ai-knowledge-sources', $filename, 'public');

        return [
            ...$extracted,
            'source_type' => 'pdf',
            'source_url' => $path ? Storage::disk('public')->url($path) : null,
            'original_filename' => $file->getClientOriginalName(),
        ];
    }

    public function extractFromDocumentUpload(UploadedFile $file): array
    {
        $extension = strtolower($file->getClientOriginalExtension());
        $title = pathinfo($file->getClientOriginalName(), PATHINFO_FILENAME);

        $cleanText = $extension === 'docx'
            ? $this->extractDocxText($file->getRealPath())
            : $this->cleanText((string) file_get_contents($file->getRealPath()));

        if (empty($cleanText)) {
            throw new Exception($extension === 'docx'
                ? 'Dokumen DOCX tidak memiliki teks yang dapat dibaca.'
                : 'Berkas TXT kosong atau tidak dapat dibaca.');
        }

        $sourceType = $extension === 'docx' ? 'docx' : 'txt';
        $filename = Str::uuid().'.'.$extension;
        $path = $file->storeAs('ai-knowledge-sources', $filename, 'public');

        return [
            'content' => mb_substr($cleanText, 0, self::MAX_CONTENT_LENGTH),
            'title' => $title,
            'source_type' => $sourceType,
            'source_url' => $path ? Storage::disk('public')->url($path) : null,
            'character_count' => mb_strlen($cleanText),
            'original_filename' => $file->getClientOriginalName(),
            'warnings' => [],
        ];
    }

    private function extractDocxText(string $path): string
    {
        try {
            $phpWord = IOFactory::load($path, 'Word2007');
        } catch (\Throwable $exception) {
            throw new Exception('Dokumen DOCX tidak valid atau rusak.');
        }

        $text = '';

        try {
            foreach ($phpWord->getSections() as $section) {
                foreach ($section->getElements() as $element) {
                    $text .= $this->elementText($element)."\n";
                }
            }
        } catch (\Throwable $exception) {
            throw new Exception('Dokumen DOCX tidak dapat dibaca. Struktur dokumen tidak didukung atau berkas rusak.');
        }

        return $this->cleanText($text);
    }

    private function elementText(mixed $element): string
    {
        if (method_exists($element, 'getText')) {
            $value = $element->getText();

            return is_string($value) ? $value : '';
        }

        if (method_exists($element, 'getElements')) {
            $text = '';
            foreach ($element->getElements() as $child) {
                $text .= $this->elementText($child).' ';
            }

            return $text;
        }

        return '';
    }

    private function extractFromPdf(string $url): array
    {
        $response = $this->guardedGet($url);

        if (! $response->successful()) {
            throw new Exception('Gagal mengunduh PDF: HTTP '.$response->status());
        }

        $contentType = strtolower((string) $response->header('Content-Type'));
        if ($contentType !== '' && ! str_contains($contentType, 'pdf') && ! str_contains($contentType, 'octet-stream')) {
            throw new Exception('File dari tautan tersebut bukan PDF yang didukung.');
        }

        $pdfContent = $response->body();

        if (strlen($pdfContent) > 5 * 1024 * 1024) {
            throw new Exception('Ukuran PDF terlalu besar (Maks 5MB).');
        }

        return [
            ...$this->parsePdfContent($pdfContent, null, 'PDF harus berupa dokumen berbasis teks dari URL publik. PDF hasil scan/foto belum dapat dibaca otomatis.'),
            'source_type' => 'pdf',
            'source_url' => $url,
        ];
    }

    private function parsePdfContent(string $pdfContent, ?string $fallbackTitle, string $emptyTextMessage): array
    {
        if (strpos($pdfContent, '%PDF') !== 0) {
            throw new Exception('File bukan PDF yang valid.');
        }

        $parser = new Parser;
        $pdf = $parser->parseContent($pdfContent);
        $cleanText = $this->cleanText($pdf->getText());

        if (empty($cleanText)) {
            throw new Exception($emptyTextMessage);
        }

        $details = $pdf->getDetails();
        $title = $details['Title'] ?? null;
        if ($title === 'Untitled' || empty(trim((string) $title))) {
            $title = $fallbackTitle;
        }

        return [
            'content' => mb_substr($cleanText, 0, self::MAX_CONTENT_LENGTH),
            'title' => $title,
            'character_count' => mb_strlen($cleanText),
            'warnings' => [],
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
