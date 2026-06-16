<?php

namespace App\Services;

use App\Exceptions\ApiException;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
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

    public function parseCsv(string $path): array
    {
        $this->validateUtf8($path);

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
                $this->validateHeader($header);

                continue;
            }

            if ($this->isEmptyRow($row)) {
                continue;
            }

            if (count($row) !== count(config('dictionary.csv_header'))) {
                throw new ApiException('Format CSV tidak valid.', 'INVALID_CSV_HEADER', 422);
            }

            $rows[] = [
                'row_number' => $rowNumber,
                'data' => array_combine(config('dictionary.csv_header'), $row),
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

    private function validateHeader(array $header): void
    {
        $expected = config('dictionary.csv_header');
        $header = array_map(fn ($value) => trim((string) $value), $header);

        if ($header !== $expected) {
            throw new ApiException('Header CSV tidak sesuai template resmi.', 'INVALID_CSV_HEADER', 422);
        }
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
