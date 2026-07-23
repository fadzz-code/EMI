<?php

namespace App\Services;

use App\Exceptions\ApiException;
use Symfony\Component\HttpFoundation\StreamedResponse;

class CsvReportExportService
{
    public function stream(string $filename, array $headers, iterable $rows, callable $mapper): StreamedResponse
    {
        $rows = collect($rows);
        $limit = (int) config('dashboard.export_max_rows');
        if ($rows->count() > $limit) {
            throw new ApiException('Jumlah row export melebihi batas.', 'REPORT_EXPORT_LIMIT_EXCEEDED', 422);
        }

        $safeFilename = preg_replace('/[^A-Za-z0-9_.-]/', '-', $filename) ?: 'report.csv';

        return response()->streamDownload(function () use ($headers, $rows, $mapper) {
            echo "\xEF\xBB\xBF";
            $handle = fopen('php://output', 'w');
            fputcsv($handle, $headers);
            foreach ($rows as $row) {
                fputcsv($handle, array_map(fn ($value) => $this->sanitizeCell($value), $mapper($row)));
            }
            fclose($handle);
        }, $safeFilename, [
            'Content-Type' => 'text/csv; charset=UTF-8',
            'Cache-Control' => 'no-store, private',
        ]);
    }

    private function sanitizeCell(mixed $value): mixed
    {
        if (! is_string($value)) {
            return $value;
        }

        return preg_match('/^[=+\-@]/', $value) === 1 ? "'{$value}" : $value;
    }
}
