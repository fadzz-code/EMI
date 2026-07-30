<?php

namespace App\Services;

use App\Models\DictionaryCategory;
use App\Models\DictionaryEntry;
use App\Models\DictionaryImportError;
use App\Models\DictionaryImportJob;
use App\Models\DictionarySentenceExample;
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

    public function preview(User $admin, UploadedFile $csvFile, ?UploadedFile $audioZip, string $duplicateStrategy, string $importType, Request $request): DictionaryImportJob
    {
        $jobId = (string) Str::uuid();
        $isXlsx = $this->fileService->isXlsx($csvFile->getClientOriginalName());
        $sourceFormat = $isXlsx ? 'xlsx' : 'csv';
        $storedFilename = $isXlsx ? 'source.xlsx' : 'source.csv';
        $csv = $this->fileService->storeUploadedFile($csvFile, $jobId, $storedFilename);
        $zip = $audioZip ? $this->fileService->storeUploadedFile($audioZip, $jobId, 'audio.zip') : null;

        try {
            $job = DictionaryImportJob::query()->create([
                'id' => $jobId,
                'uploaded_by' => $admin->id,
                'status' => 'previewing',
                'duplicate_strategy' => $duplicateStrategy,
                'import_type' => $importType,
                'source_format' => $sourceFormat,
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
        } catch (\Throwable $e) {
            if (isset($job)) {
                $job->errors()->delete();
                $job->delete();
            }
            $this->fileService->deleteImportDirectory($jobId);

            throw $e;
        }
    }

    public function analyzeJob(DictionaryImportJob $job, bool $persistErrors): array
    {
        $csvPath = $this->fileService->storagePath($job->csv_disk, $job->csv_path);
        $zipPath = $job->audio_zip_path ? $this->fileService->storagePath($job->audio_zip_disk, $job->audio_zip_path) : null;
        $zip = $this->fileService->extractZipAudio($zipPath);

        try {
            if ($job->import_type === 'combined') {
                $analysis = $this->analyzeCombinedWorkbook($job, $csvPath, $zip['files']);
            } else {
                $rows = $this->fileService->parseCsv($csvPath, $job->import_type);
                $analysis = $job->import_type === 'sentence_examples'
                    ? $this->analyzeSentenceRows($job, $rows)
                    : $this->analyzeVocabularyRows($job, $rows, $zip['files']);
            }

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

    private function analyzeCombinedWorkbook(DictionaryImportJob $job, string $xlsxPath, array $zipFiles): array
    {
        $workbook = $this->fileService->parseXlsxWorkbook($xlsxPath);

        $vocabAnalysis = $this->analyzeCombinedVocabularyRows($job, $workbook['vocabulary'], $zipFiles);
        $sentenceAnalysis = $this->analyzeCombinedSentenceRows($job, $workbook['sentence_examples'], $vocabAnalysis['valid_rows']);

        return [
            'valid_rows' => [
                'vocabulary' => $vocabAnalysis['valid_rows'],
                'sentence_examples' => $sentenceAnalysis['valid_rows'],
            ],
            'errors' => array_merge($vocabAnalysis['errors'], $sentenceAnalysis['errors']),
            'summary' => [
                'total_rows' => $vocabAnalysis['summary']['total_rows'] + $sentenceAnalysis['summary']['total_rows'],
                'valid_rows' => $vocabAnalysis['summary']['valid_rows'] + $sentenceAnalysis['summary']['valid_rows'],
                'invalid_rows' => $vocabAnalysis['summary']['invalid_rows'] + $sentenceAnalysis['summary']['invalid_rows'],
                'warning_count' => $vocabAnalysis['summary']['warning_count'] + $sentenceAnalysis['summary']['warning_count'],
                'audio_referenced' => $vocabAnalysis['summary']['audio_referenced'],
                'audio_missing' => $vocabAnalysis['summary']['audio_missing'],
                'unused_audio_files' => $vocabAnalysis['summary']['unused_audio_files'],
                'sample_rows' => array_slice(array_merge($vocabAnalysis['summary']['sample_rows'], $sentenceAnalysis['summary']['sample_rows']), 0, config('dictionary.sample_limit')),
                'sample_errors' => array_slice(array_merge($vocabAnalysis['summary']['sample_errors'], $sentenceAnalysis['summary']['sample_errors']), 0, config('dictionary.sample_limit')),
                'vocabulary' => $vocabAnalysis['summary'],
                'sentence_examples' => $sentenceAnalysis['summary'],
            ],
        ];
    }

    private function analyzeCombinedVocabularyRows(DictionaryImportJob $job, array $rows, array $zipFiles): array
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
                $this->normalizer->normalize($data['indonesia'] ?? ''),
                $this->normalizer->normalize($data['english'] ?? ''),
                $this->normalizer->normalize($data['mekongga'] ?? ''),
            ];
            $tripleKey = implode('|', $triple);

            foreach (['indonesia', 'mekongga', 'english', 'kategori'] as $field) {
                if (($data[$field] ?? '') === '') {
                    $rowErrors[] = $this->error($row['row_number'], $field, 'REQUIRED', "Kolom {$field} wajib diisi.", $data, true, 'vocabulary');
                }
            }

            $category = $categories[$this->normalizer->normalize($data['kategori'] ?? '')] ?? null;

            if (($data['kategori'] ?? '') !== '' && ! $category) {
                $rowErrors[] = $this->error($row['row_number'], 'kategori', 'CATEGORY_NOT_FOUND', 'Kategori tidak ditemukan atau tidak aktif.', $data, true, 'vocabulary');
            }

            $workbookDuplicate = isset($seen[$tripleKey]);
            if ($workbookDuplicate) {
                $duplicateRows++;
                $rowErrors[] = $this->error($row['row_number'], null, $job->duplicate_strategy === 'reject' ? 'DICTIONARY_DUPLICATE' : 'CSV_DUPLICATE_SKIPPED', $job->duplicate_strategy === 'reject' ? 'Duplikat ditemukan dalam sheet Kosakata.' : 'Duplikat dalam sheet Kosakata dilewati secara deterministik.', $data, $job->duplicate_strategy === 'reject', 'vocabulary');
            } else {
                $seen[$tripleKey] = true;
            }

            $existing = DictionaryEntry::query()
                ->where('indonesia_normalized', $triple[0])
                ->where('english_normalized', $triple[1])
                ->where('mekongga_normalized', $triple[2])
                ->first();

            if ($existing) {
                $dbDuplicates++;

                if ($job->duplicate_strategy === 'reject') {
                    $rowErrors[] = $this->error($row['row_number'], null, 'DICTIONARY_DUPLICATE', 'Entri kamus sudah ada.', $data, true, 'vocabulary');
                }
            }

            $audioFilename = $data['audio_filename'] ?? '';

            if ($audioFilename !== '') {
                if (basename($audioFilename) !== $audioFilename) {
                    $rowErrors[] = $this->error($row['row_number'], 'audio_filename', 'UNSAFE_ZIP_ENTRY', 'Nama audio tidak boleh berisi path.', $data, true, 'vocabulary');
                } elseif (! isset($zipFiles[$audioFilename])) {
                    $rowErrors[] = $this->error($row['row_number'], 'audio_filename', 'AUDIO_FILE_NOT_FOUND', "Audio \"{$audioFilename}\" tidak ditemukan karena ZIP audio tidak diunggah atau file tidak ada di ZIP. Kata tetap bisa diimpor tanpa audio.", $data, false, 'vocabulary');
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

            if ($fatalRowErrors === [] && ! $workbookDuplicate) {
                $validRows[] = [
                    'row_number' => $row['row_number'],
                    'data' => $data + ['kode' => $this->generateEntryCode($data['mekongga'], $row['row_number'])],
                    'category_id' => $category?->id,
                    'triple_key' => $tripleKey,
                    'mekongga_normalized' => $triple[2],
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
                'sheet' => 'vocabulary',
                'code' => 'UNUSED_AUDIO_FILE',
                'message' => "File audio {$filename} tidak direferensikan sheet Kosakata.",
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

    /**
     * @param  array<int, array{row_number: int, data: array<string, string>, mekongga_normalized: string}>  $validVocabRows  Rows already validated from the Kosakata sheet in this same workbook, used to auto-link sentences to a word that has not been persisted yet.
     */
    private function analyzeCombinedSentenceRows(DictionaryImportJob $job, array $rows, array $validVocabRows): array
    {
        $vocabByMekongga = [];
        foreach ($validVocabRows as $vocabRow) {
            $vocabByMekongga[$vocabRow['mekongga_normalized']][] = $vocabRow;
        }

        $seen = [];
        $validRows = [];
        $errors = [];
        $sampleRows = [];
        $sampleErrors = [];
        $duplicateRows = 0;
        $dbDuplicates = 0;

        foreach ($rows as $row) {
            $data = $this->cleanRow($row['data']);
            $rowErrors = [];

            foreach (['contoh_mekongga', 'contoh_indonesia', 'related_mekongga'] as $field) {
                if (($data[$field] ?? '') === '') {
                    $rowErrors[] = $this->error($row['row_number'], $field, 'REQUIRED', "Kolom {$field} wajib diisi.", $data, true, 'sentence_examples');
                }
            }

            $relatedNormalized = $this->normalizer->normalize($data['related_mekongga'] ?? '');
            $entries = $relatedNormalized !== ''
                ? DictionaryEntry::query()->where('mekongga_normalized', $relatedNormalized)->get()
                : collect();
            $pendingVocabRows = $vocabByMekongga[$relatedNormalized] ?? [];
            $matchCount = $entries->count() + count($pendingVocabRows);
            $entry = $matchCount === 1 ? $entries->first() : null;
            $pendingVocabRow = $matchCount === 1 && $entries->isEmpty() ? $pendingVocabRows[0] : null;

            if ($relatedNormalized !== '' && $matchCount > 1) {
                $rowErrors[] = $this->error($row['row_number'], 'related_mekongga', 'AMBIGUOUS_RELATED_MEKONGGA', "Kata Mekongga \"{$data['related_mekongga']}\" cocok dengan lebih dari satu entri.", $data, true, 'sentence_examples');
            } elseif ($relatedNormalized !== '' && $matchCount === 0) {
                $rowErrors[] = $this->error(
                    $row['row_number'],
                    'related_mekongga',
                    'RELATED_MEKONGGA_NOT_FOUND',
                    "Kata Mekongga \"{$data['related_mekongga']}\" tidak ditemukan di sheet Kosakata maupun kamus. Pastikan ejaan sama persis dengan kolom Mekongga.",
                    $data,
                    true,
                    'sentence_examples',
                );
            }

            $pair = [
                $this->normalizer->normalize($data['contoh_mekongga'] ?? ''),
                $this->normalizer->normalize($data['contoh_indonesia'] ?? ''),
            ];
            $pairKey = implode('|', $pair);

            $workbookDuplicate = isset($seen[$pairKey]);
            if ($workbookDuplicate) {
                $duplicateRows++;
                $rowErrors[] = $this->error($row['row_number'], null, $job->duplicate_strategy === 'reject' ? 'SENTENCE_DUPLICATE' : 'CSV_DUPLICATE_SKIPPED', $job->duplicate_strategy === 'reject' ? 'Contoh kalimat duplikat ditemukan dalam sheet Contoh Kalimat.' : 'Duplikat dalam sheet Contoh Kalimat dilewati secara deterministik.', $data, $job->duplicate_strategy === 'reject', 'sentence_examples');
            } else {
                $seen[$pairKey] = true;
            }

            $existing = $entry
                ? DictionarySentenceExample::query()
                    ->where('dictionary_entry_id', $entry->id)
                    ->where('example_mekongga_normalized', $pair[0])
                    ->where('example_indonesia_normalized', $pair[1])
                    ->first()
                : null;

            if ($existing) {
                $dbDuplicates++;

                if ($job->duplicate_strategy === 'reject') {
                    $rowErrors[] = $this->error($row['row_number'], null, 'SENTENCE_DUPLICATE', 'Contoh kalimat sudah ada.', $data, true, 'sentence_examples');
                }
            }

            $fatalRowErrors = array_filter($rowErrors, fn ($error) => $error['is_error']);

            foreach ($rowErrors as $error) {
                $errors[] = collect($error)->except('is_error')->all();
                if (count($sampleErrors) < config('dictionary.sample_limit')) {
                    $sampleErrors[] = collect($error)->except('is_error')->all();
                }
            }

            if ($fatalRowErrors === [] && ! $workbookDuplicate) {
                $validRows[] = [
                    'row_number' => $row['row_number'],
                    'data' => $data + ['kode' => $this->generateEntryCode($data['contoh_mekongga'], $row['row_number']).'-CK'],
                    'pair_key' => $pairKey,
                    'entry_id' => $entry?->id,
                    'pending_vocab_mekongga' => $entry ? null : $relatedNormalized,
                    'existing_id' => $existing?->id,
                ];

                if (count($sampleRows) < config('dictionary.sample_limit')) {
                    $sampleRows[] = $data;
                }
            }
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
                'audio_referenced' => 0,
                'audio_missing' => 0,
                'unused_audio_files' => 0,
                'warning_count' => count(array_filter($errors, fn ($error) => $error['code'] === 'CSV_DUPLICATE_SKIPPED')),
                'sample_rows' => $sampleRows,
                'sample_errors' => $sampleErrors,
            ],
        ];
    }

    private function generateEntryCode(string $seed, int $rowNumber): string
    {
        $slug = mb_strtoupper((string) preg_replace('/[^A-Za-z0-9]+/', '', $seed), 'UTF-8');
        $slug = mb_substr($slug, 0, 20, 'UTF-8');

        return $slug !== '' ? "{$slug}-{$rowNumber}" : "KATA-{$rowNumber}";
    }

    private function analyzeVocabularyRows(DictionaryImportJob $job, array $rows, array $zipFiles): array
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

            foreach (['kode', 'indonesia', 'english', 'mekongga', 'kategori'] as $field) {
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

    private function analyzeSentenceRows(DictionaryImportJob $job, array $rows): array
    {
        $seen = [];
        $validRows = [];
        $errors = [];
        $sampleRows = [];
        $sampleErrors = [];
        $duplicateRows = 0;
        $dbDuplicates = 0;

        foreach ($rows as $row) {
            $data = $this->cleanRow($row['data']);
            $rowErrors = [];

            foreach (['kode', 'contoh_mekongga', 'contoh_indonesia'] as $field) {
                if (($data[$field] ?? '') === '') {
                    $rowErrors[] = $this->error($row['row_number'], $field, 'REQUIRED', "Kolom {$field} wajib diisi.", $data);
                }
            }

            $pair = [
                $this->normalizer->normalize($data['contoh_mekongga']),
                $this->normalizer->normalize($data['contoh_indonesia']),
            ];
            $pairKey = implode('|', $pair);

            if (isset($seen[$pairKey])) {
                $duplicateRows++;

                if ($job->duplicate_strategy === 'reject') {
                    $rowErrors[] = $this->error($row['row_number'], null, 'SENTENCE_DUPLICATE', 'Contoh kalimat duplikat ditemukan dalam CSV.', $data);
                } else {
                    $rowErrors[] = $this->error($row['row_number'], null, 'CSV_DUPLICATE_SKIPPED', 'Duplikat dalam CSV dilewati secara deterministik.', $data, false);
                }
            }

            $entry = DictionaryEntry::query()
                ->where('code_normalized', $this->normalizer->normalize($data['kode'] ?? ''))
                ->first();

            if (($data['kode'] ?? '') !== '' && ! $entry) {
                $rowErrors[] = $this->error($row['row_number'], 'kode', 'CODE_NOT_FOUND', 'Kode tidak ditemukan di kosakata. Import kosakata terlebih dahulu.', $data);
            }

            $existing = DictionarySentenceExample::query()
                ->where('dictionary_entry_id', $entry?->id)
                ->where('example_mekongga_normalized', $pair[0])
                ->where('example_indonesia_normalized', $pair[1])
                ->first();

            if ($existing) {
                $dbDuplicates++;

                if ($job->duplicate_strategy === 'reject') {
                    $rowErrors[] = $this->error($row['row_number'], null, 'SENTENCE_DUPLICATE', 'Contoh kalimat sudah ada.', $data);
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
                $seen[$pairKey] = true;
                $validRows[] = [
                    'row_number' => $row['row_number'],
                    'data' => $data,
                    'pair_key' => $pairKey,
                    'entry_id' => $entry?->id,
                    'existing_id' => $existing?->id,
                ];

                if (count($sampleRows) < config('dictionary.sample_limit')) {
                    $sampleRows[] = $data;
                }
            }
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
                'audio_referenced' => 0,
                'audio_missing' => 0,
                'unused_audio_files' => 0,
                'warning_count' => count(array_filter($errors, fn ($error) => $error['code'] === 'CSV_DUPLICATE_SKIPPED')),
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

    private function error(?int $rowNumber, ?string $field, string $code, string $message, array $rawData, bool $isError = true, ?string $sheet = null): array
    {
        return [
            'row_number' => $rowNumber,
            'field' => $field,
            'sheet' => $sheet,
            'code' => $code,
            'message' => $message,
            'raw_data' => array_slice($rawData, 0, 20, true),
            'is_error' => $isError,
        ];
    }
}
