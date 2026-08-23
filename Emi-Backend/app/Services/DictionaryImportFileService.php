<?php

namespace App\Services;

use App\Exceptions\ApiException;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use PhpOffice\PhpSpreadsheet\IOFactory;
use PhpOffice\PhpSpreadsheet\Reader\Xlsx as XlsxReader;
use SplFileObject;
use ZipArchive;

class DictionaryImportFileService
{
    public function storeUploadedFile(UploadedFile $file, string $jobId, string $filename): array
    {
        $disk = config('dictionary.import_disk');
        $path = "dictionary/imports/{$jobId}/{$filename}";
        $stream = fopen($file->getRealPath(), 'rb');

        if ($stream === false) {
            throw new ApiException('File import tidak dapat dibaca.', 'IMPORT_FILE_READ_FAILED', 422);
        }

        try {
            $stored = Storage::disk($disk)->put($path, $stream);
        } finally {
            if (is_resource($stream)) {
                fclose($stream);
            }
        }

        if (! $stored) {
            throw new ApiException('File import gagal disimpan.', 'IMPORT_STORAGE_FAILED', 503);
        }

        return [
            'disk' => $disk,
            'path' => $path,
            'original_name' => $this->safeFilename($file->getClientOriginalName()),
            'size_bytes' => (int) $file->getSize(),
            'checksum_sha256' => hash_file('sha256', $file->getRealPath()),
        ];
    }

    public function storagePath(string $disk, string $path): string
    {
        return Storage::disk($disk)->path($path);
    }

    public function parseCsv(string $path, string $importType): array
    {
        $this->validateUtf8($path);
        $expectedHeader = config("dictionary.csv_headers.{$importType}");

        $file = new SplFileObject($path, 'rb');
        $file->setFlags(SplFileObject::READ_CSV | SplFileObject::SKIP_EMPTY);
        $file->setCsvControl(',', '"', '\\');

        $header = null;
        $rows = [];
        $rowNumber = 0;

        foreach ($file as $row) {
            if ($row === [null] || $row === false) {
                continue;
            }

            $rowNumber++;
            $row = array_map(fn ($value) => is_string($value) ? trim($value) : $value, $row);

            if ($header === null) {
                $row[0] = isset($row[0]) ? preg_replace('/^\xEF\xBB\xBF/', '', (string) $row[0]) : '';
                $header = $row;
                $this->validateHeader($header, $expectedHeader, $importType);

                continue;
            }

            if ($this->isEmptyRow($row)) {
                continue;
            }

            if (count($row) !== count($expectedHeader)) {
                throw new ApiException($this->templateErrorMessage($importType), 'INVALID_CSV_HEADER', 422);
            }

            $rows[] = [
                'row_number' => $rowNumber,
                'data' => array_combine($expectedHeader, $row),
            ];

            if (count($rows) > (int) config('dictionary.max_rows')) {
                throw new ApiException('Jumlah baris CSV melebihi batas.', 'CSV_ROW_LIMIT_EXCEEDED', 422);
            }
        }

        if ($header === null) {
            throw new ApiException('Header CSV tidak valid.', 'INVALID_CSV_HEADER', 422);
        }

        return $rows;
    }

    public function isXlsx(string $originalName): bool
    {
        return str_ends_with(mb_strtolower($originalName), '.xlsx');
    }

    public function parseXlsxWorkbook(string $path): array
    {
        if (! class_exists(IOFactory::class)) {
            throw new ApiException('Library Excel belum tersedia.', 'XLSX_LIBRARY_MISSING', 500);
        }

        try {
            $reader = new XlsxReader;
            $reader->setReadDataOnly(true);
            $spreadsheet = $reader->load($path);
        } catch (\Throwable) {
            throw new ApiException('File Excel tidak valid atau rusak.', 'INVALID_XLSX', 422);
        }

        $vocabularySheetName = (string) config('dictionary.xlsx_sheets.vocabulary');
        $sentenceSheetName = (string) config('dictionary.xlsx_sheets.sentence_examples');

        $vocabularySheet = $spreadsheet->getSheetByName($vocabularySheetName);
        $sentenceSheet = $spreadsheet->getSheetByName($sentenceSheetName);

        if (! $vocabularySheet || ! $sentenceSheet) {
            throw new ApiException(
                "Workbook harus memiliki sheet \"{$vocabularySheetName}\" dan \"{$sentenceSheetName}\". Gunakan template resmi yang bisa diunduh dari halaman ini.",
                'INVALID_XLSX_SHEETS',
                422,
            );
        }

        return [
            'vocabulary' => $this->extractSheetRows($vocabularySheet->toArray(null, true, true, false), config('dictionary.xlsx_headers.vocabulary'), 'vocabulary'),
            'sentence_examples' => $this->extractSheetRows($sentenceSheet->toArray(null, true, true, false), [
                config('dictionary.xlsx_headers.sentence_examples'),
                config('dictionary.xlsx_headers.legacy_sentence_examples'),
            ], 'sentence_examples'),
        ];
    }

    /**
     * @param  array<int, array<int, mixed>>  $sheetRows  Raw rows as returned by Worksheet::toArray()
     * @param  array<int, string>  $expectedHeader
     * @return array<int, array{row_number: int, data: array<string, string>}>
     */
    private function extractSheetRows(array $sheetRows, array $expectedHeader, string $sheetKey): array
    {
        $rows = [];
        $rowNumber = 0;
        $header = null;
        $normalizedKeys = [];

        foreach ($sheetRows as $rawRow) {
            $rowNumber++;
            $row = array_map(fn ($value) => is_string($value) ? trim($value) : (string) ($value ?? ''), $rawRow);

            if ($header === null) {
                $acceptedHeaders = isset($expectedHeader[0]) && is_array($expectedHeader[0]) ? $expectedHeader : [$expectedHeader];
                [$header, $normalizedKeys] = $this->resolveXlsxHeader($row, $acceptedHeaders, $sheetKey);

                continue;
            }

            if ($this->isEmptyRow($row)) {
                continue;
            }

            if (array_filter(array_slice($row, count($header)), fn ($value) => trim((string) $value) !== '') !== []) {
                $sheetLabel = $sheetKey === 'vocabulary' ? config('dictionary.xlsx_sheets.vocabulary') : config('dictionary.xlsx_sheets.sentence_examples');
                throw new ApiException("Sheet \"{$sheetLabel}\" memiliki kolom tambahan yang tidak diizinkan.", 'INVALID_XLSX_EXTRA_COLUMNS', 422);
            }

            $data = array_combine($normalizedKeys, array_slice(array_pad($row, count($normalizedKeys), ''), 0, count($normalizedKeys)));
            if ($sheetKey === 'sentence_examples' && count($normalizedKeys) === 3) {
                $data += ['related_indonesia' => '', 'audio_filename' => '', 'legacy_relation' => '1'];
            }

            $rows[] = [
                'row_number' => $rowNumber,
                'data' => $data,
            ];

            if (count($rows) > (int) config('dictionary.max_rows')) {
                throw new ApiException('Jumlah baris pada sheet melebihi batas.', 'XLSX_ROW_LIMIT_EXCEEDED', 422);
            }
        }

        if ($header === null) {
            throw new ApiException('Header sheet Excel tidak valid.', 'INVALID_XLSX_HEADER', 422);
        }

        return $rows;
    }

    private function resolveXlsxHeader(array $row, array $acceptedHeaders, string $sheetKey): array
    {
        foreach ($acceptedHeaders as $expected) {
            $header = array_map(fn ($value) => trim((string) $value), array_slice($row, 0, count($expected)));
            if ($header !== $expected) {
                continue;
            }

            $normalizedKeys = $sheetKey === 'vocabulary'
                ? ['indonesia', 'mekongga', 'english', 'kategori', 'audio_filename']
                : (count($expected) === 3
                    ? ['contoh_indonesia', 'contoh_mekongga', 'related_mekongga']
                    : ['related_indonesia', 'related_mekongga', 'contoh_indonesia', 'contoh_mekongga', 'audio_filename']);

            return [$header, $normalizedKeys];
        }

        $sheetLabel = $sheetKey === 'vocabulary' ? config('dictionary.xlsx_sheets.vocabulary') : config('dictionary.xlsx_sheets.sentence_examples');
        throw new ApiException(
            "Kolom pada sheet \"{$sheetLabel}\" tidak dikenali.",
            'INVALID_XLSX_HEADER',
            422,
        );
    }

    public function extractZipAudio(?string $zipPath): array
    {
        if ($zipPath === null) {
            return [
                'temp_dir' => null,
                'files' => [],
            ];
        }

        if (! class_exists(ZipArchive::class)) {
            throw new ApiException('Extension ZIP belum tersedia.', 'ZIP_EXTENSION_MISSING', 500);
        }

        $zip = new ZipArchive;
        $opened = $zip->open($zipPath);

        if ($opened !== true) {
            throw new ApiException('ZIP audio tidak valid.', 'INVALID_ZIP', 422);
        }

        $tempDir = storage_path('app/private/tmp/dictionary-import/'.Str::uuid());
        mkdir($tempDir, 0775, true);
        $files = [];
        $totalSize = 0;

        try {
            if ($zip->numFiles > (int) config('dictionary.max_audio_files')) {
                throw new ApiException('Jumlah file audio dalam ZIP melebihi batas.', 'INVALID_ZIP', 422);
            }

            for ($i = 0; $i < $zip->numFiles; $i++) {
                $stat = $zip->statIndex($i);
                $name = (string) ($stat['name'] ?? '');

                $this->validateZipEntryName($name);

                if (isset($files[$name])) {
                    throw new ApiException('Nama audio dalam ZIP duplikat.', 'DUPLICATE_AUDIO_FILENAME', 422);
                }

                $size = (int) ($stat['size'] ?? 0);
                $compressed = max(1, (int) ($stat['comp_size'] ?? 1));
                $totalSize += $size;

                if ($totalSize > (int) config('dictionary.max_uncompressed_kb') * 1024 || $size / $compressed > 1000) {
                    throw new ApiException('Ukuran ekstraksi ZIP melebihi batas.', 'ZIP_SIZE_LIMIT_EXCEEDED', 422);
                }

                $target = $tempDir.DIRECTORY_SEPARATOR.Str::uuid().'-'.basename($name);
                $stream = $zip->getStream($name);

                if ($stream === false) {
                    throw new ApiException('ZIP audio tidak valid.', 'INVALID_ZIP', 422);
                }

                $output = fopen($target, 'wb');
                stream_copy_to_stream($stream, $output);
                fclose($stream);
                fclose($output);

                $mime = mime_content_type($target) ?: '';

                if (! in_array($mime, config('media.allowed_mimes.audio'), true)) {
                    throw new ApiException('ZIP berisi file non-audio.', 'UNSUPPORTED_AUDIO', 422);
                }

                $files[$name] = [
                    'path' => $target,
                    'mime_type' => $mime,
                    'size_bytes' => $size,
                ];
            }
        } catch (ApiException $e) {
            $this->cleanupDirectory($tempDir);
            throw $e;
        } finally {
            $zip->close();
        }

        return [
            'temp_dir' => $tempDir,
            'files' => $files,
        ];
    }

    public function deleteImportDirectory(string $jobId): void
    {
        Storage::disk(config('dictionary.import_disk'))->deleteDirectory("dictionary/imports/{$jobId}");
    }

    public function cleanupDirectory(?string $dir): void
    {
        if ($dir === null || ! is_dir($dir)) {
            return;
        }

        $base = realpath(storage_path('app/private/tmp/dictionary-import'));
        $target = realpath($dir);

        if ($base === false || $target === false || ! str_starts_with($target, $base)) {
            return;
        }

        $iterator = new \RecursiveIteratorIterator(
            new \RecursiveDirectoryIterator($target, \FilesystemIterator::SKIP_DOTS),
            \RecursiveIteratorIterator::CHILD_FIRST,
        );

        foreach ($iterator as $item) {
            $item->isDir() ? rmdir($item->getPathname()) : unlink($item->getPathname());
        }

        rmdir($target);
    }

    private function validateUtf8(string $path): void
    {
        $contents = file_get_contents($path);

        if ($contents === false || ! mb_check_encoding($contents, 'UTF-8')) {
            throw new ApiException('CSV wajib memakai encoding UTF-8.', 'INVALID_CSV_ENCODING', 422);
        }
    }

    private function validateHeader(array $header, array $expected, string $importType): void
    {
        $header = array_map(fn ($value) => trim((string) $value), $header);

        if ($header !== $expected) {
            throw new ApiException($this->templateErrorMessage($importType), 'INVALID_CSV_HEADER', 422);
        }
    }

    private function templateErrorMessage(string $importType): string
    {
        return $importType === 'sentence_examples'
            ? 'Template CSV tidak sesuai. Gunakan template Contoh Kalimat.'
            : 'Template CSV tidak sesuai. Gunakan template Kosakata.';
    }

    private function validateZipEntryName(string $name): void
    {
        $lower = mb_strtolower($name, 'UTF-8');

        if (
            $name === ''
            || str_contains($name, '/')
            || str_contains($name, '\\')
            || str_contains($name, '..')
            || str_starts_with($name, '/')
            || preg_match('/^[a-zA-Z]:/', $name)
            || preg_match('/\.(zip|rar|php|js|html|exe|apk)$/i', $name)
            || ! preg_match('/\.(mp3|wav|m4a|ogg|webm)$/i', $lower)
        ) {
            throw new ApiException('ZIP berisi entry yang tidak aman.', 'UNSAFE_ZIP_ENTRY', 422);
        }
    }

    private function isEmptyRow(array $row): bool
    {
        return collect($row)->every(fn ($value) => trim((string) $value) === '');
    }

    private function safeFilename(string $name): string
    {
        $safe = preg_replace('/[^\w.\- ]+/', '_', $name) ?: 'import';

        return trim($safe) !== '' ? trim($safe) : 'import';
    }
}
