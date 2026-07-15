<?php

namespace App\Services;

class SimplePdfService
{
    private const PAGE_WIDTH = 595;

    private const PAGE_HEIGHT = 842;

    private const MARGIN = 42;

    private array $pages = [];

    private array $commands = [];

    private float $y = 0;

    private string $title = '';

    public function make(array $report): string
    {
        $this->pages = [];
        $this->title = (string) $report['title'];
        $this->newPage();
        $this->heading('EMI - E-Learning Mekongga Indonesia', 10);
        $this->heading($this->title, 18);
        $this->text('Tanggal cetak: '.now()->locale('id')->translatedFormat('d F Y H:i'));

        foreach ($report['sections'] as $section) {
            $this->section($section);
        }

        $this->finishPage();

        return $this->build();
    }

    private function section(array $section): void
    {
        $this->ensureSpace(42);
        $this->y -= 8;
        $this->heading((string) $section['title'], 13);

        if (isset($section['items'])) {
            $this->items($section['items']);
        }
        if (isset($section['note'])) {
            $this->text((string) $section['note']);
        }
        if (isset($section['headers'], $section['rows'])) {
            $this->table($section['headers'], $section['rows'], $section['widths'] ?? []);
        }
    }

    private function items(array $items): void
    {
        foreach ($items as $label => $value) {
            $this->ensureSpace(16);
            $this->text($label.': '.$this->value($value), 10, 48);
        }
    }

    private function table(array $headers, array $rows, array $widths): void
    {
        $widths = $widths ?: array_fill(0, count($headers), (self::PAGE_WIDTH - self::MARGIN * 2) / count($headers));
        $rows = $rows ?: [array_merge(['Belum ada data sesuai filter.'], array_fill(1, count($headers) - 1, ''))];
        $this->tableHeader($headers, $widths);

        foreach ($rows as $row) {
            $height = $this->rowHeight($row, $widths);
            if ($this->y - $height < 55) {
                $this->finishPage();
                $this->newPage();
                $this->tableHeader($headers, $widths);
            }
            $this->tableRow($row, $widths, $height);
        }
    }

    private function tableHeader(array $headers, array $widths): void
    {
        $this->ensureSpace(24);
        $this->tableRow($headers, $widths, 22, true);
    }

    private function tableRow(array $cells, array $widths, float $height, bool $bold = false): void
    {
        $x = self::MARGIN;
        foreach ($widths as $index => $width) {
            $this->rect($x, $this->y - $height, $width, $height, $bold);
            $lines = $this->wrap($this->value($cells[$index] ?? null), $width);
            foreach (array_slice($lines, 0, max(1, (int) (($height - 6) / 10))) as $line => $text) {
                $this->drawText($text, $x + 3, $this->y - 12 - ($line * 10), 8, $bold);
            }
            $x += $width;
        }
        $this->y -= $height;
    }

    private function rowHeight(array $row, array $widths): float
    {
        $lines = 1;
        foreach ($widths as $index => $width) {
            $lines = max($lines, count($this->wrap($this->value($row[$index] ?? null), $width)));
        }

        return min(52, max(20, 8 + ($lines * 10)));
    }

    private function wrap(string $text, float $width): array
    {
        return explode("\n", wordwrap($text, max(4, (int) floor(($width - 6) / 4.5)), "\n", true));
    }

    private function heading(string $text, int $size): void
    {
        $this->ensureSpace($size + 8);
        $this->drawText($text, self::MARGIN, $this->y, $size, true);
        $this->y -= $size + 6;
    }

    private function text(string $text, int $size = 9, float $indent = 0): void
    {
        foreach ($this->wrap($text, self::PAGE_WIDTH - self::MARGIN * 2 - $indent) as $line) {
            $this->ensureSpace($size + 4);
            $this->drawText($line, self::MARGIN + $indent, $this->y, $size);
            $this->y -= $size + 3;
        }
    }

    private function ensureSpace(float $height): void
    {
        if ($this->y - $height < 55) {
            $this->finishPage();
            $this->newPage();
        }
    }

    private function newPage(): void
    {
        $this->commands = [];
        $this->y = self::PAGE_HEIGHT - self::MARGIN;
    }

    private function finishPage(): void
    {
        if ($this->commands === []) {
            return;
        }
        $page = count($this->pages) + 1;
        $this->drawText('Dicetak dari Admin EMI | Halaman '.$page, self::MARGIN, 30, 8);
        $this->pages[] = implode("\n", $this->commands)."\n";
        $this->commands = [];
    }

    private function drawText(string $text, float $x, float $y, int $size, bool $bold = false): void
    {
        $font = $bold ? 'F2' : 'F1';
        $this->commands[] = "BT /{$font} {$size} Tf {$x} {$y} Td (".$this->escape($text).') Tj ET';
    }

    private function rect(float $x, float $y, float $width, float $height, bool $fill): void
    {
        if ($fill) {
            $this->commands[] = "0.92 g {$x} {$y} {$width} {$height} re f 0 g";
        }
        $this->commands[] = "{$x} {$y} {$width} {$height} re S";
    }

    private function value(mixed $value): string
    {
        if ($value === null || $value === '') {
            return '-';
        }
        if ($value instanceof \DateTimeInterface) {
            return $value->format('d-m-Y H:i');
        }

        return (string) $value;
    }

    private function escape(string $value): string
    {
        $value = mb_convert_encoding($value, 'Windows-1252', 'UTF-8');

        return str_replace(['\\', '(', ')', "\r", "\n"], ['\\\\', '\\(', '\\)', '', ' '], $value);
    }

    private function build(): string
    {
        $objects = [1 => '<< /Type /Catalog /Pages 2 0 R >>'];
        $kids = [];
        $next = 5;
        foreach ($this->pages as $content) {
            $pageId = $next++;
            $contentId = $next++;
            $kids[] = "{$pageId} 0 R";
            $objects[$pageId] = "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> /Contents {$contentId} 0 R >>";
            $objects[$contentId] = '<< /Length '.strlen($content).">>\nstream\n{$content}endstream";
        }
        $objects[2] = '<< /Type /Pages /Kids ['.implode(' ', $kids).'] /Count '.count($kids).' >>';
        $objects[3] = '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>';
        $objects[4] = '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>';
        ksort($objects);
        $pdf = "%PDF-1.4\n%\xE2\xE3\xCF\xD3\n";
        $offsets = [0];
        foreach ($objects as $id => $object) {
            $offsets[$id] = strlen($pdf);
            $pdf .= "{$id} 0 obj\n{$object}\nendobj\n";
        }
        $xref = strlen($pdf);
        $pdf .= "xref\n0 ".(count($objects) + 1)."\n0000000000 65535 f \n";
        for ($id = 1; $id <= count($objects); $id++) {
            $pdf .= sprintf("%010d 00000 n \n", $offsets[$id]);
        }

        return $pdf.'trailer << /Size '.(count($objects) + 1).' /Root 1 0 R >>'."\nstartxref\n{$xref}\n%%EOF\n";
    }
}
