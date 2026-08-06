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
                'audio' => $vocabAnalysis['summary']['audio'],
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
        $existingByTriple = $this->existingEntriesByTriple();
        $seen = [];
        $validRows = [];
        $errors = [];
        $sampleRows = [];
        $sampleErrors = [];
        $duplicateRows = 0;
        $audioReferenced = [];
        $dbDuplicates = 0;
        $errorBreakdown = [];

        foreach ($rows as $row) {
            $data = $this->cleanRow($row['data']);
            $rowErrors = [];
            $triple = [
                $this->normalizer->normalize($data['indonesia'] ?? ''),
                $this->normalizer->normalize($data['english'] ?? ''),
                $this->normalizer->normalize($data['mekongga'] ?? ''),
            ];
            $tripleKey = implode('|', $triple);

            if (($data['indonesia'] ?? '') === '') {
                $rowErrors[] = $this->error($row['row_number'], 'indonesia', 'REQUIRED', 'Kolom Bahasa Indonesia kosong. Saran: isi kata Indonesia-nya; kolom lain boleh dikosongkan dulu.', $data, true, 'vocabulary');
            }

            $category = $categories[$this->normalizer->normalize($data['kategori'] ?? '')] ?? null;

            if (($data['kategori'] ?? '') !== '' && ! $category) {
                $rowErrors[] = $this->error($row['row_number'], 'kategori', 'CATEGORY_NOT_FOUND', "Kategori \"{$data['kategori']}\" tidak ada atau nonaktif. Saran: pilih kategori dari menu Kamus, atau kosongkan kolomnya.", $data, true, 'vocabulary');
            }

            $workbookDuplicate = isset($seen[$tripleKey]);
            if ($workbookDuplicate) {
                $duplicateRows++;
                $rowErrors[] = $this->error($row['row_number'], null, $job->duplicate_strategy === 'reject' ? 'DICTIONARY_DUPLICATE' : 'CSV_DUPLICATE_SKIPPED', $job->duplicate_strategy === 'reject' ? 'Baris ini sama persis dengan baris lain di sheet Kosakata. Saran: hapus salah satu baris.' : 'Baris ini sama dengan baris lain di sheet Kosakata, jadi otomatis dilewati. Saran: hapus baris gandanya.', $data, $job->duplicate_strategy === 'reject', 'vocabulary');
            } else {
                $seen[$tripleKey] = true;
            }

            $existingId = $existingByTriple[$tripleKey] ?? null;

            if ($existingId !== null) {
                $dbDuplicates++;

                if ($job->duplicate_strategy === 'reject') {
                    $rowErrors[] = $this->error($row['row_number'], null, 'DICTIONARY_DUPLICATE', 'Kata ini sudah ada di kamus. Saran: ganti strategi duplikat ke "Lewati" atau "Perbarui".', $data, true, 'vocabulary');
                }
            }

            [$resolvedAudio, $audioError] = $this->resolveAudio($data['audio_filename'] ?? '', $data['mekongga'] ?? '', $zipFiles, $row['row_number'], $data, 'vocabulary');
            $data['audio_filename'] = $resolvedAudio ?? '';
            if ($audioError) {
                $rowErrors[] = $audioError;
            }
            if ($resolvedAudio !== null) {
                $audioReferenced[$resolvedAudio] = true;
            }

            $fatalRowErrors = array_filter($rowErrors, fn ($error) => $error['is_error']);

            foreach ($fatalRowErrors as $fatalError) {
                $errorBreakdown[$fatalError['code']] = ($errorBreakdown[$fatalError['code']] ?? 0) + 1;
            }

            foreach ($rowErrors as $error) {
                $errors[] = collect($error)->except('is_error')->all();
                if (count($sampleErrors) < config('dictionary.sample_limit')) {
                    $sampleErrors[] = collect($error)->except('is_error')->all();
                }
            }

            if ($fatalRowErrors === [] && ! $workbookDuplicate) {
                $validRows[] = [
                    'row_number' => $row['row_number'],
                    'data' => $data + ['kode' => $this->generateEntryCode($data['mekongga'] ?? '', $row['row_number'])],
                    'category_id' => $category?->id,
                    'triple_key' => $tripleKey,
                    'mekongga_normalized' => $triple[2],
                    'existing_id' => $existingId,
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
                'audio_missing' => count(array_filter($errors, fn ($error) => in_array($error['code'], ['AUDIO_FILE_NOT_FOUND', 'AUDIO_AUTO_NOT_FOUND'], true))),
                'unused_audio_files' => count($unusedAudio),
                'audio' => $this->audioSummary($zipFiles, $audioReferenced, $errors, $unusedAudio),
                'warning_count' => count($unusedAudio) + count(array_filter($errors, fn ($error) => in_array($error['code'], ['CSV_DUPLICATE_SKIPPED', 'AUDIO_FILE_NOT_FOUND', 'AUDIO_AUTO_NOT_FOUND', 'AUDIO_AUTO_AMBIGUOUS'], true))),
                'error_breakdown' => $errorBreakdown,
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

        $relatedValues = collect($rows)
            ->map(fn (array $row): string => $this->normalizer->normalize($row['data']['related_mekongga'] ?? ''))
            ->filter()
            ->unique()
            ->values();
        $entriesByMekongga = $relatedValues->isEmpty()
            ? collect()
            : DictionaryEntry::query()->whereIn('mekongga_normalized', $relatedValues)->get()->groupBy('mekongga_normalized');
        $existingSentences = DictionarySentenceExample::query()
            ->whereIn('dictionary_entry_id', $entriesByMekongga->flatten(1)->pluck('id'))
            ->get(['id', 'dictionary_entry_id', 'example_mekongga_normalized', 'example_indonesia_normalized'])
            ->keyBy(fn (DictionarySentenceExample $sentence): string => implode('|', [$sentence->dictionary_entry_id, $sentence->example_mekongga_normalized, $sentence->example_indonesia_normalized]));

        $seen = [];
        $validRows = [];
        $errors = [];
        $sampleRows = [];
        $sampleErrors = [];
        $duplicateRows = 0;
        $dbDuplicates = 0;
        $errorBreakdown = [];

        foreach ($rows as $row) {
            $data = $this->cleanRow($row['data']);
            $rowErrors = [];

            if (($data['contoh_indonesia'] ?? '') === '') {
                $rowErrors[] = $this->error($row['row_number'], 'contoh_indonesia', 'REQUIRED', 'Kolom Bahasa Indonesia kosong. Saran: isi kalimat Indonesia-nya; contoh Mekongga boleh menyusul.', $data, true, 'sentence_examples');
            }

            if (($data['related_mekongga'] ?? '') === '') {
                $rowErrors[] = $this->error($row['row_number'], 'related_mekongga', 'REQUIRED', 'Kolom Kata Mekongga Terkait kosong. Saran: isi kata Mekongga yang punya contoh ini, persis seperti di sheet Kosakata.', $data, true, 'sentence_examples');
            }

            $relatedNormalized = $this->normalizer->normalize($data['related_mekongga'] ?? '');
            $entries = $relatedNormalized !== ''
                ? collect($entriesByMekongga[$relatedNormalized] ?? [])
                : collect();
            $pendingVocabRows = $vocabByMekongga[$relatedNormalized] ?? [];
            $matchCount = $entries->count() + count($pendingVocabRows);
            $entry = $matchCount === 1 ? $entries->first() : null;

            if ($relatedNormalized !== '' && $matchCount > 1) {
                $rowErrors[] = $this->error($row['row_number'], 'related_mekongga', 'AMBIGUOUS_RELATED_MEKONGGA', "Kata Mekongga \"{$data['related_mekongga']}\" cocok dengan lebih dari satu entri kamus. Saran: perjelas kata terkait atau rapikan duplikat entri di kamus.", $data, true, 'sentence_examples');
            } elseif ($relatedNormalized !== '' && $matchCount === 0) {
                $rowErrors[] = $this->error(
                    $row['row_number'],
                    'related_mekongga',
                    'RELATED_MEKONGGA_NOT_FOUND',
                    "Kata Mekongga \"{$data['related_mekongga']}\" tidak ditemukan di sheet Kosakata maupun kamus. Saran: impor kata itu dulu di sheet Kosakata, atau samakan ejaannya persis dengan kolom Mekongga.",
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
                $rowErrors[] = $this->error($row['row_number'], null, $job->duplicate_strategy === 'reject' ? 'SENTENCE_DUPLICATE' : 'CSV_DUPLICATE_SKIPPED', $job->duplicate_strategy === 'reject' ? 'Kalimat ini sama dengan baris lain di sheet Contoh Kalimat. Saran: hapus salah satu baris.' : 'Kalimat ini sama dengan baris lain di sheet Contoh Kalimat, jadi otomatis dilewati. Saran: hapus baris gandanya.', $data, $job->duplicate_strategy === 'reject', 'sentence_examples');
            } else {
                $seen[$pairKey] = true;
            }

            $existingId = $entry
                ? ($existingSentences[implode('|', [$entry->id, $pair[0], $pair[1]])] ?? null)
                : null;

            if ($existingId !== null) {
                $dbDuplicates++;

                if ($job->duplicate_strategy === 'reject') {
                    $rowErrors[] = $this->error($row['row_number'], null, 'SENTENCE_DUPLICATE', 'Contoh kalimat ini sudah ada di kamus. Saran: ganti strategi duplikat ke "Lewati" atau "Perbarui".', $data, true, 'sentence_examples');
                }
            }

            $fatalRowErrors = array_filter($rowErrors, fn ($error) => $error['is_error']);

            foreach ($fatalRowErrors as $fatalError) {
                $errorBreakdown[$fatalError['code']] = ($errorBreakdown[$fatalError['code']] ?? 0) + 1;
            }

            foreach ($rowErrors as $error) {
                $errors[] = collect($error)->except('is_error')->all();
                if (count($sampleErrors) < config('dictionary.sample_limit')) {
                    $sampleErrors[] = collect($error)->except('is_error')->all();
                }
            }

            if ($fatalRowErrors === [] && ! $workbookDuplicate) {
                $validRows[] = [
                    'row_number' => $row['row_number'],
                    'data' => $data + ['kode' => $this->generateEntryCode($data['contoh_mekongga'] ?? '', $row['row_number']).'-CK'],
                    'pair_key' => $pairKey,
                    'entry_id' => $entry?->id,
                    'pending_vocab_mekongga' => $entry ? null : $relatedNormalized,
                    'existing_id' => $existingId,
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
                'error_breakdown' => $errorBreakdown,
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
        $existingByTriple = $this->existingEntriesByTriple();
        $seen = [];
        $validRows = [];
        $errors = [];
        $sampleRows = [];
        $sampleErrors = [];
        $duplicateRows = 0;
        $audioReferenced = [];
        $dbDuplicates = 0;
        $errorBreakdown = [];

        foreach ($rows as $row) {
            $data = $this->cleanRow($row['data']);
            $rowErrors = [];
            $triple = [
                $this->normalizer->normalize($data['indonesia'] ?? ''),
                $this->normalizer->normalize($data['english'] ?? ''),
                $this->normalizer->normalize($data['mekongga'] ?? ''),
            ];
            $tripleKey = implode('|', $triple);

            if (($data['indonesia'] ?? '') === '') {
                $rowErrors[] = $this->error($row['row_number'], 'indonesia', 'REQUIRED', 'Kolom Bahasa Indonesia kosong. Saran: isi kata Indonesia-nya; kolom lain boleh dikosongkan dulu.', $data);
            }

            $category = $categories[$this->normalizer->normalize($data['kategori'] ?? '')] ?? null;

            if (($data['kategori'] ?? '') !== '' && ! $category) {
                $rowErrors[] = $this->error($row['row_number'], 'kategori', 'CATEGORY_NOT_FOUND', "Kategori \"{$data['kategori']}\" tidak ada atau nonaktif. Saran: pilih kategori dari menu Kamus, atau kosongkan kolomnya.", $data);
            }

            if (isset($seen[$tripleKey])) {
                $duplicateRows++;

                if ($job->duplicate_strategy === 'reject') {
                    $rowErrors[] = $this->error($row['row_number'], null, 'DICTIONARY_DUPLICATE', 'Baris ini sama persis dengan baris lain di CSV. Saran: hapus salah satu baris.', $data);
                } else {
                    $rowErrors[] = $this->error($row['row_number'], null, 'CSV_DUPLICATE_SKIPPED', 'Baris ini sama dengan baris lain di CSV, jadi otomatis dilewati. Saran: hapus baris gandanya.', $data, false);
                }
            }

            $existingId = $existingByTriple[$tripleKey] ?? null;

            if ($existingId !== null) {
                $dbDuplicates++;

                if ($job->duplicate_strategy === 'reject') {
                    $rowErrors[] = $this->error($row['row_number'], null, 'DICTIONARY_DUPLICATE', 'Kata ini sudah ada di kamus. Saran: ganti strategi duplikat ke "Lewati" atau "Perbarui".', $data);
                }
            }

            [$resolvedAudio, $audioError] = $this->resolveAudio($data['audio_filename'] ?? '', $data['mekongga'] ?? '', $zipFiles, $row['row_number'], $data);
            $data['audio_filename'] = $resolvedAudio ?? '';
            if ($audioError) {
                $rowErrors[] = $audioError;
            }
            if ($resolvedAudio !== null) {
                $audioReferenced[$resolvedAudio] = true;
            }

            $fatalRowErrors = array_filter($rowErrors, fn ($error) => $error['is_error']);

            foreach ($fatalRowErrors as $fatalError) {
                $errorBreakdown[$fatalError['code']] = ($errorBreakdown[$fatalError['code']] ?? 0) + 1;
            }

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
                    'data' => $data + ['kode' => ($data['kode'] ?? '') !== '' ? $data['kode'] : $this->generateEntryCode($data['mekongga'] ?? '', $row['row_number'])],
                    'category_id' => $category?->id,
                    'triple_key' => $tripleKey,
                    'existing_id' => $existingId,
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
                'audio_missing' => count(array_filter($errors, fn ($error) => in_array($error['code'], ['AUDIO_FILE_NOT_FOUND', 'AUDIO_AUTO_NOT_FOUND'], true))),
                'unused_audio_files' => count($unusedAudio),
                'audio' => $this->audioSummary($zipFiles, $audioReferenced, $errors, $unusedAudio),
                'warning_count' => count($unusedAudio) + count(array_filter($errors, fn ($error) => in_array($error['code'], ['CSV_DUPLICATE_SKIPPED', 'AUDIO_FILE_NOT_FOUND', 'AUDIO_AUTO_NOT_FOUND', 'AUDIO_AUTO_AMBIGUOUS'], true))),
                'error_breakdown' => $errorBreakdown,
                'sample_rows' => $sampleRows,
                'sample_errors' => $sampleErrors,
            ],
        ];
    }

    private function analyzeSentenceRows(DictionaryImportJob $job, array $rows): array
    {
        $codes = collect($rows)
            ->map(fn (array $row): string => $this->normalizer->normalize($row['data']['kode'] ?? ''))
            ->filter()
            ->unique()
            ->values();
        $entriesByCode = $codes->isEmpty()
            ? collect()
            : DictionaryEntry::query()->whereIn('code_normalized', $codes)->get()->keyBy('code_normalized');
        $existingSentences = DictionarySentenceExample::query()
            ->whereIn('dictionary_entry_id', $entriesByCode->pluck('id'))
            ->get(['id', 'dictionary_entry_id', 'example_mekongga_normalized', 'example_indonesia_normalized'])
            ->keyBy(fn (DictionarySentenceExample $sentence): string => implode('|', [$sentence->dictionary_entry_id, $sentence->example_mekongga_normalized, $sentence->example_indonesia_normalized]));

        $seen = [];
        $validRows = [];
        $errors = [];
        $sampleRows = [];
        $sampleErrors = [];
        $duplicateRows = 0;
        $dbDuplicates = 0;
        $errorBreakdown = [];

        foreach ($rows as $row) {
            $data = $this->cleanRow($row['data']);
            $rowErrors = [];

            if (($data['kode'] ?? '') === '') {
                $rowErrors[] = $this->error($row['row_number'], 'kode', 'REQUIRED', 'Kolom kode kosong. Saran: isi kode kata dari sheet Kosakata agar kalimat tertaut ke kata yang benar.', $data);
            }

            if (($data['contoh_indonesia'] ?? '') === '') {
                $rowErrors[] = $this->error($row['row_number'], 'contoh_indonesia', 'REQUIRED', 'Kolom Bahasa Indonesia kosong. Saran: isi kalimat Indonesia-nya; contoh Mekongga boleh menyusul.', $data);
            }

            $pair = [
                $this->normalizer->normalize($data['contoh_mekongga'] ?? ''),
                $this->normalizer->normalize($data['contoh_indonesia'] ?? ''),
            ];
            $pairKey = implode('|', $pair);

            if (isset($seen[$pairKey])) {
                $duplicateRows++;

                if ($job->duplicate_strategy === 'reject') {
                    $rowErrors[] = $this->error($row['row_number'], null, 'SENTENCE_DUPLICATE', 'Kalimat ini sama dengan baris lain di CSV. Saran: hapus salah satu baris.', $data);
                } else {
                    $rowErrors[] = $this->error($row['row_number'], null, 'CSV_DUPLICATE_SKIPPED', 'Kalimat ini sama dengan baris lain di CSV, jadi otomatis dilewati. Saran: hapus baris gandanya.', $data, false);
                }
            }

            $entry = $entriesByCode[$this->normalizer->normalize($data['kode'] ?? '')] ?? null;

            if (($data['kode'] ?? '') !== '' && ! $entry) {
                $rowErrors[] = $this->error($row['row_number'], 'kode', 'CODE_NOT_FOUND', "Kode \"{$data['kode']}\" tidak ada di kamus. Saran: impor kosakata dulu, atau periksa ejaan kodenya.", $data);
            }

            $existingId = $entry
                ? ($existingSentences[implode('|', [$entry->id, $pair[0], $pair[1]])] ?? null)
                : null;

            if ($existingId !== null) {
                $dbDuplicates++;

                if ($job->duplicate_strategy === 'reject') {
                    $rowErrors[] = $this->error($row['row_number'], null, 'SENTENCE_DUPLICATE', 'Contoh kalimat ini sudah ada di kamus. Saran: ganti strategi duplikat ke "Lewati" atau "Perbarui".', $data);
                }
            }

            $fatalRowErrors = array_filter($rowErrors, fn ($error) => $error['is_error']);

            foreach ($fatalRowErrors as $fatalError) {
                $errorBreakdown[$fatalError['code']] = ($errorBreakdown[$fatalError['code']] ?? 0) + 1;
            }

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
                    'existing_id' => $existingId,
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
                'error_breakdown' => $errorBreakdown,
                'sample_rows' => $sampleRows,
                'sample_errors' => $sampleErrors,
            ],
        ];
    }

    private function existingEntriesByTriple(): array
    {
        return DictionaryEntry::query()
            ->select(['id', 'indonesia_normalized', 'english_normalized', 'mekongga_normalized'])
            ->get()
            ->mapWithKeys(fn (DictionaryEntry $entry): array => [implode('|', [$entry->indonesia_normalized, $entry->english_normalized, $entry->mekongga_normalized]) => $entry->id])
            ->all();
    }

    private function resolveAudio(string $explicit, string $mekongga, array $zipFiles, int $rowNumber, array $data, ?string $sheet = null): array
    {
        if ($explicit !== '') {
            if (basename($explicit) !== $explicit) {
                return [null, $this->error($rowNumber, 'audio_filename', 'UNSAFE_ZIP_ENTRY', 'Nama audio tidak boleh berisi path.', $data, true, $sheet)];
            }

            return isset($zipFiles[$explicit])
                ? [$explicit, null]
                : [null, $this->error($rowNumber, 'audio_filename', 'AUDIO_FILE_NOT_FOUND', "Audio \"{$explicit}\" tidak ditemukan karena ZIP audio tidak diunggah atau file tidak ada di ZIP. Kata tetap bisa diimpor tanpa audio.", $data, false, $sheet)];
        }

        if ($zipFiles === [] || $mekongga === '') {
            return [null, null];
        }

        $key = $this->audioKey($mekongga);
        $matches = array_values(array_filter(array_keys($zipFiles), fn ($filename) => $this->audioKey(pathinfo($filename, PATHINFO_FILENAME)) === $key));
        sort($matches, SORT_STRING);

        if (count($matches) === 1) {
            return [$matches[0], null];
        }

        if ($matches === []) {
            return [null, $this->error($rowNumber, 'audio_filename', 'AUDIO_AUTO_NOT_FOUND', "Audio untuk kata Mekongga \"{$mekongga}\" tidak ditemukan.", $data, false, $sheet)];
        }

        return [null, $this->error($rowNumber, 'audio_filename', 'AUDIO_AUTO_AMBIGUOUS', "Audio untuk kata Mekongga \"{$mekongga}\" ambigu.", $data, false, $sheet)];
    }

    private function audioKey(string $value): string
    {
        return preg_replace('/[^\pL\pN]+/u', '', $this->normalizer->normalize($value)) ?: '';
    }

    private function audioSummary(array $zipFiles, array $referenced, array $errors, array $unused): array
    {
        return [
            'files_found' => count($zipFiles),
            'matched' => count($referenced),
            'missing' => count(array_filter($errors, fn ($error) => in_array($error['code'], ['AUDIO_FILE_NOT_FOUND', 'AUDIO_AUTO_NOT_FOUND'], true))),
            'ambiguous' => count(array_filter($errors, fn ($error) => $error['code'] === 'AUDIO_AUTO_AMBIGUOUS')),
            'unused' => count($unused),
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
