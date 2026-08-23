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
        $sentenceAnalysis = $this->analyzeCombinedSentenceRows($job, $workbook['sentence_examples'], $vocabAnalysis['valid_rows'], $zipFiles);

        $audioReferenced = array_keys($vocabAnalysis['audio_referenced'] + $sentenceAnalysis['audio_referenced']);
        $unusedAudio = array_values(array_diff(array_keys($zipFiles), $audioReferenced));
        $errors = array_merge($vocabAnalysis['errors'], $sentenceAnalysis['errors']);
        $errors = array_values(array_filter(
            $errors,
            fn (array $error) => ! ($error['code'] === 'UNUSED_AUDIO_FILE' && isset($vocabAnalysis['audio_referenced'][$error['raw_data']['audio_filename'] ?? '']) === false && isset($sentenceAnalysis['audio_referenced'][$error['raw_data']['audio_filename'] ?? '']))
        ));

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
            'valid_rows' => [
                'vocabulary' => $vocabAnalysis['valid_rows'],
                'sentence_examples' => $sentenceAnalysis['valid_rows'],
            ],
            'errors' => $errors,
            'summary' => [
                'total_rows' => $vocabAnalysis['summary']['total_rows'] + $sentenceAnalysis['summary']['total_rows'],
                'valid_rows' => $vocabAnalysis['summary']['valid_rows'] + $sentenceAnalysis['summary']['valid_rows'],
                'invalid_rows' => $vocabAnalysis['summary']['invalid_rows'] + $sentenceAnalysis['summary']['invalid_rows'],
                'warning_count' => $vocabAnalysis['summary']['warning_count'] + $sentenceAnalysis['summary']['warning_count'],
                'audio_referenced' => count($audioReferenced),
                'audio_missing' => count(array_filter($errors, fn ($error) => in_array($error['code'], ['AUDIO_FILE_NOT_FOUND', 'AUDIO_AUTO_NOT_FOUND'], true))),
                'unused_audio_files' => count($unusedAudio),
                'audio' => $this->audioSummary($zipFiles, array_flip($audioReferenced), $errors, $unusedAudio),
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
        $existingByIndonesia = $this->existingEntriesByIndonesia();
        $validatedRows = [];
        $errors = [];
        $sampleRows = [];
        $sampleErrors = [];
        $errorBreakdown = [];
        $invalidCount = 0;

        foreach ($rows as $row) {
            $data = $this->cleanRow($row['data']);
            $rowErrors = [];

            if (($data['indonesia'] ?? '') === '') {
                $rowErrors[] = $this->error($row['row_number'], 'indonesia', 'REQUIRED', 'Kolom Bahasa Indonesia kosong. Saran: isi kata Indonesia-nya; kolom lain boleh dikosongkan dulu.', $data, true, 'vocabulary');
            }

            [$category, $categoryAlias] = $this->resolveCategory($data['kategori'] ?? '', $categories);

            if ($categoryAlias !== null) {
                $data['kategori'] = $categoryAlias;
                $rowErrors[] = $this->error($row['row_number'], 'kategori', 'CATEGORY_NORMALIZED', "Kategori dinormalisasi menjadi \"{$categoryAlias}\".", $data, false, 'vocabulary');
            } elseif (($data['kategori'] ?? '') !== '' && ! $category) {
                $rowErrors[] = $this->error($row['row_number'], 'kategori', 'WARNING_UNKNOWN_CATEGORY', "Kategori \"{$data['kategori']}\" tidak dikenal. Kosakata tetap diproses tanpa kategori.", $data, false, 'vocabulary');
            }

            $fatalRowErrors = array_filter($rowErrors, fn ($error) => $error['is_error']);

            if ($fatalRowErrors !== []) {
                $invalidCount++;
            }

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
                $validatedRows[] = [
                    'row_number' => $row['row_number'],
                    'data' => $data,
                    'category' => $category,
                ];
            }
        }

        $merged = [];
        foreach ($validatedRows as $item) {
            $key = $this->normalizer->normalize($item['data']['indonesia']);
            $mekonggaKey = $this->normalizer->normalize($item['data']['mekongga'] ?? '');
            $categoryId = $item['category']?->id;

            $mergeKey = $key.'|'.($mekonggaKey !== '' ? $mekonggaKey : 'no_mek');

            if (! isset($merged[$mergeKey])) {
                $merged[$mergeKey] = [
                    'row_number' => $item['row_number'],
                    'data' => $item['data'],
                    'indonesia_key' => $key,
                    'merge_key' => $mergeKey,
                    'category_id' => $categoryId,
                    'count' => 1,
                ];

                continue;
            }

            $merged[$mergeKey]['count']++;
            foreach (['indonesia', 'mekongga', 'english', 'kategori', 'audio_filename'] as $field) {
                if (($item['data'][$field] ?? '') !== '') {
                    $merged[$mergeKey]['data'][$field] = $item['data'][$field];
                }
            }
            if ($categoryId !== null) {
                $merged[$mergeKey]['category_id'] = $categoryId;
            }
        }

        $duplicateRows = 0;
        $dbDuplicates = 0;
        $audioReferenced = [];
        $validRows = [];

        foreach ($merged as $mergeKey => $candidate) {
            $duplicateRows += $candidate['count'] - 1;
            $key = $candidate['indonesia_key'];
            $rowNumber = $candidate['row_number'];
            $data = $candidate['data'];
            $existingIds = $existingByIndonesia[$key] ?? [];
            $rowErrors = [];

            $existingId = null;
            $mekonggaNormalized = $this->normalizer->normalize($data['mekongga'] ?? '');

            if (count($existingIds) === 1) {
                $existingId = $existingIds[0];
            } elseif (count($existingIds) > 1) {
                if ($mekonggaNormalized === '') {
                    $rowErrors[] = $this->error($rowNumber, 'indonesia', 'AMBIGUOUS_INDONESIA', "Kata Indonesia \"{$data['indonesia']}\" memiliki beberapa padanan Mekongga. Isi kolom Mekongga untuk menentukan kosakata yang ingin diperbarui.", $data, true, 'vocabulary');
                } else {
                    $matches = DictionaryEntry::query()
                        ->whereIn('id', $existingIds)
                        ->where('mekongga_normalized', $mekonggaNormalized)
                        ->pluck('id');

                    if ($matches->count() === 1) {
                        $existingId = $matches->first();
                    } elseif ($matches->count() > 1) {
                        $rowErrors[] = $this->error($rowNumber, 'indonesia', 'AMBIGUOUS_INDONESIA_MEKONGGA', "Kombinasi kata Indonesia \"{$data['indonesia']}\" dan Mekongga \"{$data['mekongga']}\" cocok dengan lebih dari satu entri.", $data, true, 'vocabulary');
                    }
                }
            }
            if ($existingId !== null) {
                $dbDuplicates++;
            }

            [$resolvedAudio, $audioError] = $this->resolveAudio($data['audio_filename'] ?? '', count($existingIds) === 1 ? [$data['indonesia'] ?? '', $data['mekongga'] ?? '', $data['english'] ?? ''] : [$data['mekongga'] ?? '', $data['english'] ?? ''], $zipFiles, $rowNumber, $data, 'vocabulary');
            $data['audio_filename'] = $resolvedAudio ?? '';
            if ($audioError) {
                $rowErrors[] = $audioError;
            }
            if ($resolvedAudio !== null) {
                $audioReferenced[$resolvedAudio] = true;
            }

            $fatalRowErrors = array_filter($rowErrors, fn ($error) => $error['is_error']);

            if ($fatalRowErrors !== []) {
                $invalidCount++;
            }

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
                $validRows[] = [
                    'row_number' => $rowNumber,
                    'data' => $data + ['kode' => $this->generateEntryCode($data['mekongga'] ?? '', $rowNumber)],
                    'category_id' => $candidate['category_id'],
                    'indonesia_key' => $key,
                    'merge_key' => $mergeKey,
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
            'audio_referenced' => $audioReferenced,
            'summary' => [
                'total_rows' => count($rows),
                'valid_rows' => count($validRows),
                'invalid_rows' => $invalidCount,
                'new_rows' => count(array_filter($validRows, fn ($row) => $row['existing_id'] === null)),
                'duplicate_rows' => $duplicateRows + $dbDuplicates,
                'audio_referenced' => count($audioReferenced),
                'audio_missing' => count(array_filter($errors, fn ($error) => in_array($error['code'], ['AUDIO_FILE_NOT_FOUND', 'AUDIO_AUTO_NOT_FOUND'], true))),
                'unused_audio_files' => count($unusedAudio),
                'audio' => $this->audioSummary($zipFiles, $audioReferenced, $errors, $unusedAudio),
                'warning_count' => count($unusedAudio) + count(array_filter($errors, fn ($error) => in_array($error['code'], ['CSV_DUPLICATE_SKIPPED', 'AUDIO_FILE_NOT_FOUND', 'AUDIO_AUTO_NOT_FOUND', 'AUDIO_AUTO_AMBIGUOUS', 'CATEGORY_NORMALIZED', 'WARNING_UNKNOWN_CATEGORY'], true))),
                'categories_normalized' => count(array_filter($errors, fn ($error) => $error['code'] === 'CATEGORY_NORMALIZED')),
                'unknown_categories' => count(array_filter($errors, fn ($error) => $error['code'] === 'WARNING_UNKNOWN_CATEGORY')),
                'error_breakdown' => $errorBreakdown,
                'sample_rows' => $sampleRows,
                'sample_errors' => $sampleErrors,
            ],
        ];
    }

    /**
     * @param  array<int, array{row_number: int, data: array<string, string>, indonesia_key: string, category_id: string|null, existing_id: string|null}>  $validVocabRows  Rows already validated and merged from the Kosakata sheet in this same workbook, used to auto-link sentences to a word that has not been persisted yet.
     */
    private function analyzeCombinedSentenceRows(DictionaryImportJob $job, array $rows, array $validVocabRows, array $zipFiles): array
    {
        $pendingByIndonesia = [];
        foreach ($validVocabRows as $vocabRow) {
            $pendingByIndonesia[$vocabRow['indonesia_key']][] = $vocabRow;
        }

        $rows = $this->adaptLegacySentenceRows($rows, $validVocabRows);

        $relatedValues = collect($rows)
            ->map(fn (array $row): string => $this->normalizer->normalize($row['data']['related_indonesia'] ?? ''))
            ->filter()
            ->unique()
            ->values();
        $entriesByIndonesia = $relatedValues->isEmpty()
            ? collect()
            : DictionaryEntry::query()->whereIn('indonesia_normalized', $relatedValues)->get()->groupBy('indonesia_normalized');
        $existingSentences = DictionarySentenceExample::query()
            ->whereIn('dictionary_entry_id', $entriesByIndonesia->flatten(1)->pluck('id'))
            ->get(['id', 'dictionary_entry_id', 'example_indonesia_normalized'])
            ->keyBy(fn (DictionarySentenceExample $sentence): string => implode('|', [$sentence->dictionary_entry_id, $sentence->example_indonesia_normalized]));

        $validatedRows = [];
        $errors = [];
        $sampleRows = [];
        $sampleErrors = [];
        $errorBreakdown = [];
        $invalidCount = 0;

        foreach ($rows as $row) {
            $data = $this->cleanRow($row['data']);
            $rowErrors = [];

            if (($data['contoh_indonesia'] ?? '') === '') {
                $rowErrors[] = $this->error($row['row_number'], 'contoh_indonesia', 'REQUIRED', 'Kolom Bahasa Indonesia kosong. Saran: isi kalimat Indonesia-nya; contoh Mekongga boleh menyusul.', $data, true, 'sentence_examples');
            }

            if (($data['legacy_relation_error'] ?? '') !== '') {
                $code = $data['legacy_relation_error'];
                $message = $code === 'AMBIGUOUS_LEGACY_MEKONGGA_RELATION'
                    ? "Kata Mekongga terkait \"{$data['related_mekongga']}\" cocok dengan lebih dari satu kosakata."
                    : "Kata Mekongga terkait \"{$data['related_mekongga']}\" tidak ditemukan.";
                $rowErrors[] = $this->error($row['row_number'], 'related_mekongga', $code, $message, $data, true, 'sentence_examples');
            } elseif (($data['related_indonesia'] ?? '') === '') {
                $rowErrors[] = $this->error($row['row_number'], 'related_indonesia', 'REQUIRED', 'Kolom Kata Indonesia Terkait kosong. Saran: isi kata Indonesia yang punya contoh ini, persis seperti di sheet Kosakata.', $data, true, 'sentence_examples');
            }

            $relatedNormalized = $this->normalizer->normalize($data['related_indonesia'] ?? '');
            $relatedMekonggaNormalized = $this->normalizer->normalize($data['related_mekongga'] ?? '');

            $pendingMatch = null;
            if (isset($pendingByIndonesia[$relatedNormalized])) {
                $matches = collect($pendingByIndonesia[$relatedNormalized]);
                if ($matches->count() === 1) {
                    $pendingMatch = $matches->first();
                } else {
                    if ($relatedMekonggaNormalized === '') {
                        $rowErrors[] = $this->error($row['row_number'], 'related_indonesia', 'AMBIGUOUS_RELATED_INDONESIA', "Kata \"{$data['related_indonesia']}\" memiliki beberapa padanan Mekongga. Isi 'Kata Mekongga Terkait' pada sheet Contoh Kalimat.", $data, true, 'sentence_examples');
                    } else {
                        $subMatches = $matches->filter(fn ($m) => $this->normalizer->normalize($m['data']['mekongga'] ?? '') === $relatedMekonggaNormalized);
                        if ($subMatches->count() === 1) {
                            $pendingMatch = $subMatches->first();
                        } elseif ($subMatches->count() > 1) {
                            $rowErrors[] = $this->error($row['row_number'], 'related_indonesia', 'AMBIGUOUS_RELATED_INDONESIA_MEKONGGA', "Kombinasi kata terkait \"{$data['related_indonesia']}\" dan \"{$data['related_mekongga']}\" cocok dengan lebih dari satu baris Kosakata baru.", $data, true, 'sentence_examples');
                        } else {
                            $rowErrors[] = $this->error($row['row_number'], 'related_indonesia', 'RELATED_INDONESIA_MEKONGGA_NOT_FOUND', "Kombinasi kata terkait \"{$data['related_indonesia']}\" dan \"{$data['related_mekongga']}\" tidak ditemukan.", $data, true, 'sentence_examples');
                        }
                    }
                }
            }

            $existingMatch = null;
            if (! $pendingMatch && isset($entriesByIndonesia[$relatedNormalized])) {
                $matches = $entriesByIndonesia[$relatedNormalized];
                if ($matches->count() === 1) {
                    $existingMatch = $matches->first();
                } else {
                    if ($relatedMekonggaNormalized === '') {
                        $rowErrors[] = $this->error($row['row_number'], 'related_indonesia', 'AMBIGUOUS_RELATED_INDONESIA', "Kata \"{$data['related_indonesia']}\" memiliki beberapa padanan Mekongga. Isi 'Kata Mekongga Terkait' pada sheet Contoh Kalimat.", $data, true, 'sentence_examples');
                    } else {
                        $subMatches = $matches->filter(fn ($m) => $m->mekongga_normalized === $relatedMekonggaNormalized);
                        if ($subMatches->count() === 1) {
                            $existingMatch = $subMatches->first();
                        } elseif ($subMatches->count() > 1) {
                            $rowErrors[] = $this->error($row['row_number'], 'related_indonesia', 'AMBIGUOUS_RELATED_INDONESIA_MEKONGGA', "Kombinasi kata terkait \"{$data['related_indonesia']}\" dan \"{$data['related_mekongga']}\" cocok dengan lebih dari satu entri kamus.", $data, true, 'sentence_examples');
                        } else {
                            $rowErrors[] = $this->error($row['row_number'], 'related_indonesia', 'RELATED_INDONESIA_MEKONGGA_NOT_FOUND', "Kombinasi kata terkait \"{$data['related_indonesia']}\" dan \"{$data['related_mekongga']}\" tidak ditemukan di kamus.", $data, true, 'sentence_examples');
                        }
                    }
                }
            }

            if ($relatedNormalized !== '' && ! $pendingMatch && ! $existingMatch && ! array_filter($rowErrors, fn ($error) => $error['is_error'])) {
                $rowErrors[] = $this->error(
                    $row['row_number'],
                    'related_indonesia',
                    'RELATED_INDONESIA_NOT_FOUND',
                    "Kata Indonesia \"{$data['related_indonesia']}\" tidak ditemukan di sheet Kosakata maupun kamus. Saran: impor kata itu dulu di sheet Kosakata, atau samakan ejaannya persis dengan kolom Indonesia.",
                    $data,
                    true,
                    'sentence_examples',
                );
            }

            $entry = $existingMatch;
            $pendingKey = ($entry === null && $pendingMatch !== null) ? $pendingMatch['merge_key'] : null;

            [$resolvedAudio, $audioError] = $this->resolveAudio($data['audio_filename'] ?? '', [], $zipFiles, $row['row_number'], $data, 'sentence_examples');
            $data['audio_filename'] = $resolvedAudio ?? '';
            if ($audioError) {
                $rowErrors[] = $audioError;
            }

            $fatalRowErrors = array_filter($rowErrors, fn ($error) => $error['is_error']);

            if ($fatalRowErrors !== []) {
                $invalidCount++;
            }

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
                $validatedRows[] = [
                    'row_number' => $row['row_number'],
                    'data' => $data,
                    'entry_id' => $entry?->id,
                    'pending_vocab_indonesia' => $pendingKey,
                    'sentence_key' => $this->normalizer->normalize($data['contoh_indonesia'] ?? ''),
                    'existing_id' => $entry ? ($existingSentences[implode('|', [$entry->id, $this->normalizer->normalize($data['contoh_indonesia'] ?? '')])] ?? null) : null,
                ];
            }
        }

        $merged = [];
        foreach ($validatedRows as $item) {
            $key = implode('|', [$item['entry_id'] ?? 'pending:'.$item['pending_vocab_indonesia'].':'.($item['data']['related_mekongga'] ?? ''), $item['sentence_key']]);

            if (! isset($merged[$key])) {
                $merged[$key] = $item + ['count' => 1];

                continue;
            }

            $merged[$key]['count']++;
            foreach (['contoh_indonesia', 'contoh_mekongga', 'audio_filename'] as $field) {
                if (($item['data'][$field] ?? '') !== '') {
                    $merged[$key]['data'][$field] = $item['data'][$field];
                }
            }
            $merged[$key]['existing_id'] = $merged[$key]['existing_id'] ?? $item['existing_id'];
        }

        $duplicateRows = 0;
        $dbDuplicates = 0;
        $audioReferenced = [];
        $validRows = [];

        foreach ($merged as $candidate) {
            $duplicateRows += $candidate['count'] - 1;
            $rowNumber = $candidate['row_number'];
            $data = $candidate['data'];

            if ($candidate['existing_id'] !== null) {
                $dbDuplicates++;
            }

            if (($data['audio_filename'] ?? '') !== '') {
                $audioReferenced[$data['audio_filename']] = true;
            }

            $validRows[] = [
                'row_number' => $rowNumber,
                'data' => $data + ['kode' => $this->generateEntryCode($data['contoh_mekongga'] ?? '', $rowNumber).'-CK'],
                'entry_id' => $candidate['entry_id'],
                'pending_vocab_indonesia' => $candidate['pending_vocab_indonesia'],
                'pair_key' => implode('|', [$this->normalizer->normalize($data['contoh_mekongga'] ?? ''), $this->normalizer->normalize($data['contoh_indonesia'] ?? '')]),
                'existing_id' => $candidate['existing_id'],
            ];

            if (count($sampleRows) < config('dictionary.sample_limit')) {
                $sampleRows[] = $data;
            }
        }

        return [
            'valid_rows' => $validRows,
            'errors' => $errors,
            'audio_referenced' => $audioReferenced,
            'summary' => [
                'total_rows' => count($rows),
                'valid_rows' => count($validRows),
                'invalid_rows' => $invalidCount,
                'new_rows' => count(array_filter($validRows, fn ($row) => $row['existing_id'] === null)),
                'duplicate_rows' => $duplicateRows + $dbDuplicates,
                'audio_referenced' => count($audioReferenced),
                'audio_missing' => 0,
                'unused_audio_files' => 0,
                'warning_count' => count(array_filter($errors, fn ($error) => in_array($error['code'], ['CSV_DUPLICATE_SKIPPED', 'AUDIO_FILE_NOT_FOUND'], true))),
                'error_breakdown' => $errorBreakdown,
                'sample_rows' => $sampleRows,
                'sample_errors' => $sampleErrors,
            ],
        ];
    }

    private function adaptLegacySentenceRows(array $rows, array $validVocabRows): array
    {
        $legacyRows = array_filter($rows, fn (array $row): bool => ($row['data']['legacy_relation'] ?? '') === '1');
        if ($legacyRows === []) {
            return $rows;
        }

        $pendingByMekongga = collect($validVocabRows)
            ->filter(fn (array $row): bool => $this->normalizer->normalize($row['data']['mekongga'] ?? '') !== '')
            ->groupBy(fn (array $row): string => $this->normalizer->normalize($row['data']['mekongga']));
        $tokens = collect($legacyRows)
            ->flatMap(fn (array $row): array => preg_split('/\s*[,;\/]\s*/u', $row['data']['related_mekongga'] ?? '', -1, PREG_SPLIT_NO_EMPTY) ?: [])
            ->map(fn (string $token): string => $this->normalizer->normalize($token))
            ->filter()
            ->unique();
        $existingByMekongga = $tokens->isEmpty()
            ? collect()
            : DictionaryEntry::query()->where('status', 'active')->whereIn('mekongga_normalized', $tokens)->get()->groupBy('mekongga_normalized');
        $adapted = [];

        foreach ($rows as $row) {
            if (($row['data']['legacy_relation'] ?? '') !== '1') {
                $adapted[] = $row;

                continue;
            }

            $relatedTokens = preg_split('/\s*[,;\/]\s*/u', $row['data']['related_mekongga'] ?? '', -1, PREG_SPLIT_NO_EMPTY) ?: [''];
            foreach ($relatedTokens as $token) {
                $key = $this->normalizer->normalize($token);
                $matches = $pendingByMekongga->get($key, collect());
                if ($matches->isEmpty()) {
                    $matches = $existingByMekongga->get($key, collect());
                }

                $data = $row['data'];
                $data['related_mekongga'] = $this->normalizer->normalizeDisplay($token) ?? '';
                if ($matches->count() === 1) {
                    $match = $matches->first();
                    $data['related_indonesia'] = is_array($match) ? $match['data']['indonesia'] : $match->indonesia;
                } else {
                    $data['legacy_relation_error'] = $matches->isEmpty()
                        ? 'LEGACY_MEKONGGA_RELATION_NOT_FOUND'
                        : 'AMBIGUOUS_LEGACY_MEKONGGA_RELATION';
                }
                $adapted[] = ['row_number' => $row['row_number'], 'data' => $data];
            }
        }

        return $adapted;
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
        $invalidCount = 0;

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

            [$resolvedAudio, $audioError] = $this->resolveAudio($data['audio_filename'] ?? '', [$data['mekongga'] ?? ''], $zipFiles, $row['row_number'], $data);
            $data['audio_filename'] = $resolvedAudio ?? '';
            if ($audioError) {
                $rowErrors[] = $audioError;
            }
            if ($resolvedAudio !== null) {
                $audioReferenced[$resolvedAudio] = true;
            }

            $fatalRowErrors = array_filter($rowErrors, fn ($error) => $error['is_error']);

            if ($fatalRowErrors !== []) {
                $invalidCount++;
            }

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
                'invalid_rows' => $invalidCount,
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
        $invalidCount = 0;

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

            if ($fatalRowErrors !== []) {
                $invalidCount++;
            }

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
                'invalid_rows' => $invalidCount,
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

    private function resolveCategory(string $value, $categories): array
    {
        $key = $this->normalizer->normalize($value);
        $category = $categories[$key] ?? null;
        if ($category || $key === '') {
            return [$category, null];
        }

        $aliases = [
            'frasa kata benda' => 'frase kata benda',
            'keta benda' => 'kata benda',
            'kata beda' => 'kata benda',
            'kata penghubung' => 'kata penghubung/sambung',
        ];
        $alias = $aliases[$key] ?? null;

        return [$alias !== null ? ($categories[$alias] ?? null) : null, $alias !== null && isset($categories[$alias]) ? $categories[$alias]->name : null];
    }

    private function existingEntriesByTriple(): array
    {
        return DictionaryEntry::query()
            ->select(['id', 'indonesia_normalized', 'english_normalized', 'mekongga_normalized'])
            ->get()
            ->mapWithKeys(fn (DictionaryEntry $entry): array => [implode('|', [$entry->indonesia_normalized, $entry->english_normalized, $entry->mekongga_normalized]) => $entry->id])
            ->all();
    }

    private function existingEntriesByIndonesia(): array
    {
        return DictionaryEntry::query()
            ->select(['id', 'indonesia_normalized'])
            ->where('status', 'active')
            ->get()
            ->groupBy('indonesia_normalized')
            ->map(fn ($entries): array => $entries->pluck('id')->values()->all())
            ->all();
    }

    private function resolveAudio(string $explicit, array $priorityValues, array $zipFiles, int $rowNumber, array $data, ?string $sheet = null): array
    {
        if ($explicit !== '') {
            if (basename($explicit) !== $explicit) {
                return [null, $this->error($rowNumber, 'audio_filename', 'UNSAFE_ZIP_ENTRY', 'Nama audio tidak boleh berisi path.', $data, true, $sheet)];
            }

            return isset($zipFiles[$explicit])
                ? [$explicit, null]
                : [null, $this->error($rowNumber, 'audio_filename', 'AUDIO_FILE_NOT_FOUND', "Audio \"{$explicit}\" tidak ditemukan karena ZIP audio tidak diunggah atau file tidak ada di ZIP. Kata tetap bisa diimpor tanpa audio.", $data, false, $sheet)];
        }

        $candidates = array_values(array_filter($priorityValues, fn ($value) => $value !== ''));

        if ($zipFiles === [] || $candidates === []) {
            return [null, null];
        }

        foreach ($candidates as $value) {
            $key = $this->audioKey($value);
            $matches = array_values(array_filter(array_keys($zipFiles), fn ($filename) => $this->audioKey(pathinfo($filename, PATHINFO_FILENAME)) === $key));
            sort($matches, SORT_STRING);

            if (count($matches) === 1) {
                return [$matches[0], null];
            }

            if (count($matches) > 1) {
                return [null, $this->error($rowNumber, 'audio_filename', 'AUDIO_AUTO_AMBIGUOUS', "Audio untuk kata \"{$value}\" ambigu.", $data, false, $sheet)];
            }
        }

        return [null, $this->error($rowNumber, 'audio_filename', 'AUDIO_AUTO_NOT_FOUND', "Audio untuk kata \"{$candidates[0]}\" tidak ditemukan.", $data, false, $sheet)];
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
