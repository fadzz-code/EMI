<?php

namespace App\Services;

use App\Models\DictionaryCategory;
use App\Models\DictionaryEntry;
use App\Models\DictionaryImportError;
use App\Models\DictionaryImportJob;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Str;

class DictionaryImportPreviewService
{
    public function __construct(
        private readonly AuditLogService $auditLogService,
        private readonly DictionaryImportFileService $fileService,
        private readonly DictionaryNormalizer $normalizer,
    ) {}

    public function preview(User $admin, UploadedFile $csvFile, ?UploadedFile $audioZip, string $duplicateStrategy, Request $request): DictionaryImportJob
    {
        $jobId = (string) Str::uuid();
        $csv = $this->fileService->storeUploadedFile($csvFile, $jobId, 'source.csv');
        $zip = $audioZip ? $this->fileService->storeUploadedFile($audioZip, $jobId, 'audio.zip') : null;

        $job = DictionaryImportJob::query()->create([
            'id' => $jobId,
            'uploaded_by' => $admin->id,
            'status' => 'previewing',
            'duplicate_strategy' => $duplicateStrategy,
            'csv_disk' => $csv['disk'],
            'csv_path' => $csv['path'],
            'csv_original_name' => $csv['original_name'],
            'csv_size_bytes' => $csv['size_bytes'],
            'csv_checksum_sha256' => $csv['checksum_sha256'],
            'audio_zip_disk' => $zip['disk'] ?? null,
            'audio_zip_path' => $zip['path'] ?? null,
            'audio_zip_original_name' => $zip['original_name'] ?? null,
            'audio_zip_size_bytes' => $zip['size_bytes'] ?? null,
            'audio_zip_checksum_sha256' => $zip['checksum_sha256'] ?? null,
        ]);

        $analysis = $this->analyzeJob($job, true);

        $job->forceFill([
            'status' => 'preview_ready',
            'total_rows' => $analysis['summary']['total_rows'],
            'valid_rows' => $analysis['summary']['valid_rows'],
            'invalid_rows' => $analysis['summary']['invalid_rows'],
            'warning_count' => $analysis['summary']['warning_count'],
            'summary' => $analysis['summary'],
        ])->save();

        $this->auditLogService->record('dictionary.import_previewed', $job, $admin, null, [
            'status' => 'preview_ready',
            'total_rows' => $job->total_rows,
            'valid_rows' => $job->valid_rows,
            'invalid_rows' => $job->invalid_rows,
        ], [], $request);

        return $job->refresh();
    }

    public function analyzeJob(DictionaryImportJob $job, bool $persistErrors): array
    {
        $csvPath = $this->fileService->storagePath($job->csv_disk, $job->csv_path);
        $zipPath = $job->audio_zip_path ? $this->fileService->storagePath($job->audio_zip_disk, $job->audio_zip_path) : null;
        $zip = $this->fileService->extractZipAudio($zipPath);

        try {
            $rows = $this->fileService->parseCsv($csvPath);
            $analysis = $this->analyzeRows($job, $rows, $zip['files']);

            if ($persistErrors) {
                DictionaryImportError::query()->where('import_job_id', $job->id)->delete();
                foreach ($analysis['errors'] as $error) {
                    DictionaryImportError::query()->create($error + ['import_job_id' => $job->id, 'created_at' => now()]);
                }
            }

            return [
                'rows' => $analysis['valid_rows'],
                'zip_files' => $zip['files'],
                'zip_temp_dir' => $zip['temp_dir'],
                'summary' => $analysis['summary'],
            ];
        } finally {
            if ($persistErrors) {
                $this->fileService->cleanupDirectory($zip['temp_dir']);
            }
        }
    }

    private function analyzeRows(DictionaryImportJob $job, array $rows, array $zipFiles): array
    {
        $categories = DictionaryCategory::query()
            ->active()
            ->get()
            ->keyBy(fn (DictionaryCategory $category) => $this->normalizer->normalize($category->name));
        $seen = [];
        $validRows = [];
        $errors = [];
        $sampleRows = [];
        $sampleErrors = [];
        $duplicateRows = 0;
        $audioReferenced = [];
        $dbDuplicates = 0;

        foreach ($rows as $row) {
            $data = $this->cleanRow($row['data']);
            $rowErrors = [];
            $triple = [
                $this->normalizer->normalize($data['indonesia']),
                $this->normalizer->normalize($data['english']),
                $this->normalizer->normalize($data['mekongga']),
            ];
            $tripleKey = implode('|', $triple);

            foreach (['indonesia', 'english', 'mekongga', 'kategori'] as $field) {
                if (($data[$field] ?? '') === '') {
                    $rowErrors[] = $this->error($row['row_number'], $field, 'REQUIRED', "Kolom {$field} wajib diisi.", $data);
                }
            }

            $category = $categories[$this->normalizer->normalize($data['kategori'] ?? '')] ?? null;

            if (($data['kategori'] ?? '') !== '' && ! $category) {
                $rowErrors[] = $this->error($row['row_number'], 'kategori', 'CATEGORY_NOT_FOUND', 'Kategori tidak ditemukan atau tidak aktif.', $data);
            }

            if (isset($seen[$tripleKey])) {
                $duplicateRows++;

                if ($job->duplicate_strategy === 'reject') {
                    $rowErrors[] = $this->error($row['row_number'], null, 'DICTIONARY_DUPLICATE', 'Duplikat ditemukan dalam CSV.', $data);
                } else {
                    $rowErrors[] = $this->error($row['row_number'], null, 'CSV_DUPLICATE_SKIPPED', 'Duplikat dalam CSV dilewati secara deterministik.', $data, false);
                }
            }

            $existing = DictionaryEntry::query()
                ->where('indonesia_normalized', $triple[0])
                ->where('english_normalized', $triple[1])
                ->where('mekongga_normalized', $triple[2])
                ->first();

            if ($existing) {
                $dbDuplicates++;

                if ($job->duplicate_strategy === 'reject') {
                    $rowErrors[] = $this->error($row['row_number'], null, 'DICTIONARY_DUPLICATE', 'Entri kamus sudah ada.', $data);
                }
            }

            $audioFilename = $data['audio_filename'] ?? '';

            if ($audioFilename !== '') {
                if (basename($audioFilename) !== $audioFilename) {
                    $rowErrors[] = $this->error($row['row_number'], 'audio_filename', 'UNSAFE_ZIP_ENTRY', 'Nama audio tidak boleh berisi path.', $data);
                } elseif (! isset($zipFiles[$audioFilename])) {
                    $rowErrors[] = $this->error($row['row_number'], 'audio_filename', 'AUDIO_FILE_NOT_FOUND', "Audio \"{$audioFilename}\" tidak ditemukan karena ZIP audio tidak diunggah atau file tidak ada di ZIP. Kata tetap bisa diimpor tanpa audio.", $data, false);
                } else {
                    $audioReferenced[$audioFilename] = true;
                }
            }

            $fatalRowErrors = array_filter($rowErrors, fn ($error) => $error['is_error']);

            foreach ($rowErrors as $error) {
                $errors[] = collect($error)->except('is_error')->all();
                if (count($sampleErrors) < config('dictionary.sample_limit')) {
                    $sampleErrors[] = collect($error)->except('is_error')->all();
                }
            }

            if ($fatalRowErrors === []) {
                $seen[$tripleKey] = true;
                $validRows[] = [
                    'row_number' => $row['row_number'],
                    'data' => $data,
                    'category_id' => $category?->id,
                    'triple_key' => $tripleKey,
                    'existing_id' => $existing?->id,
                ];

                if (count($sampleRows) < config('dictionary.sample_limit')) {
                    $sampleRows[] = $data;
                }
            }
        }

        $unusedAudio = array_values(array_diff(array_keys($zipFiles), array_keys($audioReferenced)));

        foreach ($unusedAudio as $filename) {
            $errors[] = [
                'row_number' => null,
                'field' => 'audio_zip',
                'code' => 'UNUSED_AUDIO_FILE',
                'message' => "File audio {$filename} tidak direferensikan CSV.",
                'raw_data' => ['audio_filename' => $filename],
            ];
        }

        return [
            'valid_rows' => $validRows,
            'errors' => $errors,
            'summary' => [
                'total_rows' => count($rows),
                'valid_rows' => count($validRows),
                'invalid_rows' => count($rows) - count($validRows),
                'new_rows' => count(array_filter($validRows, fn ($row) => $row['existing_id'] === null)),
                'duplicate_rows' => $duplicateRows + $dbDuplicates,
                'audio_referenced' => count($audioReferenced),
                'audio_missing' => count(array_filter($errors, fn ($error) => $error['code'] === 'AUDIO_FILE_NOT_FOUND')),
                'unused_audio_files' => count($unusedAudio),
                'warning_count' => count($unusedAudio) + count(array_filter($errors, fn ($error) => in_array($error['code'], ['CSV_DUPLICATE_SKIPPED', 'AUDIO_FILE_NOT_FOUND'], true))),
                'sample_rows' => $sampleRows,
                'sample_errors' => $sampleErrors,
            ],
        ];
    }

    private function cleanRow(array $data): array
    {
        return collect($data)
            ->map(fn ($value) => $this->normalizer->normalizeDisplay((string) $value) ?? '')
            ->all();
    }

    private function error(?int $rowNumber, ?string $field, string $code, string $message, array $rawData, bool $isError = true): array
    {
        return [
            'row_number' => $rowNumber,
            'field' => $field,
            'code' => $code,
            'message' => $message,
            'raw_data' => array_slice($rawData, 0, 20, true),
            'is_error' => $isError,
        ];
    }
}
