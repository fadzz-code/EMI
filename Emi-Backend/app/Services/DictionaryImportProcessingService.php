<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\DictionaryEntry;
use App\Models\DictionaryImportJob;
use App\Models\DictionarySentenceExample;
use App\Models\MediaFile;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Throwable;

class DictionaryImportProcessingService
{
    public function __construct(
        private readonly AuditLogService $auditLogService,
        private readonly DictionaryEntryService $dictionaryEntryService,
        private readonly DictionaryImportFileService $fileService,
        private readonly DictionaryImportPreviewService $previewService,
        private readonly MediaUploadService $mediaUploadService,
    ) {}

    public function process(string $jobId): DictionaryImportJob
    {
        $job = DictionaryImportJob::query()->findOrFail($jobId);
        $actor = $job->uploader;
        $analysis = null;

        try {
            DB::transaction(function () use ($job): void {
                $locked = DictionaryImportJob::query()->whereKey($job->id)->lockForUpdate()->firstOrFail();

                if ($locked->status !== 'queued') {
                    throw new ApiException('Status import tidak valid.', 'INVALID_IMPORT_STATUS', 409);
                }

                $locked->forceFill([
                    'status' => 'processing',
                    'started_at' => now(),
                    'failure_code' => null,
                    'failure_message' => null,
                ])->save();
            });

            $job = $job->refresh();
            $analysis = $this->previewService->analyzeJob($job, false);

            if ($job->import_type === 'combined') {
                return $this->processCombinedWorkbook($job, $actor, $analysis);
            }

            if ($job->import_type === 'sentence_examples') {
                return $this->processSentenceExamples($job, $actor, $analysis);
            }

            $mediaByFilename = [];
            $inserted = 0;
            $updated = 0;
            $skipped = 0;
            $processedTriples = [];
            $chunkSize = max(1, (int) config('dictionary.chunk_size'));

            foreach (array_chunk($analysis['rows'], $chunkSize) as $chunk) {
                DB::transaction(function () use ($chunk, $job, $actor, &$mediaByFilename, &$inserted, &$updated, &$skipped, &$processedTriples, $analysis): void {
                    foreach ($chunk as $row) {
                        if (isset($processedTriples[$row['triple_key']])) {
                            $skipped++;

                            continue;
                        }

                        $processedTriples[$row['triple_key']] = true;
                        $data = $row['data'];
                        $existing = DictionaryEntry::query()->whereKey($row['existing_id'])->first();

                        if ($existing && $job->duplicate_strategy === 'skip') {
                            $skipped++;

                            continue;
                        }

                        $audioMediaId = null;
                        if (($data['audio_filename'] ?? '') !== '' && isset($analysis['zip_files'][$data['audio_filename']])) {
                            $audioMediaId = $mediaByFilename[$data['audio_filename']] ??= $this->createAudioMedia($job, $actor, $data['audio_filename'], $analysis['zip_files'][$data['audio_filename']]['path']);
                        }

                        $payload = [
                            'category_id' => $row['category_id'],
                            'code' => $data['kode'],
                            'indonesia' => $data['indonesia'],
                            'english' => $data['english'],
                            'mekongga' => $data['mekongga'],
                            'example_mekongga' => null,
                            'example_indonesia' => null,
                            'audio_media_id' => $audioMediaId,
                            'status' => 'active',
                        ];

                        if ($existing && $job->duplicate_strategy === 'update') {
                            $existing->fill($this->dictionaryEntryService->payload(array_merge($payload, [
                                'audio_media_id' => $audioMediaId ?? $existing->audio_media_id,
                            ])) + [
                                'updated_by' => $actor->id,
                                'source_import_job_id' => $job->id,
                            ])->save();
                            $updated++;

                            continue;
                        }

                        if (! $existing) {
                            DictionaryEntry::query()->create($this->dictionaryEntryService->payload($payload) + [
                                'created_by' => $actor->id,
                                'source_import_job_id' => $job->id,
                            ]);
                            $inserted++;
                        }
                    }
                });
            }

            $status = $job->invalid_rows > 0 ? 'completed_with_errors' : 'completed';
            $job->forceFill([
                'status' => $status,
                'inserted_rows' => $inserted,
                'updated_rows' => $updated,
                'skipped_rows' => $skipped,
                'summary' => $this->withAudioResult((array) $job->summary, count($mediaByFilename)),
                'completed_at' => now(),
            ])->save();

            $this->auditLogService->record(
                $status === 'completed' ? 'dictionary.import_completed' : 'dictionary.import_completed_with_errors',
                $job,
                $actor,
                null,
                $job->only(['status', 'inserted_rows', 'updated_rows', 'skipped_rows']),
            );

            return $job->refresh();
        } catch (Throwable $e) {
            $safeCode = $e instanceof ApiException ? $e->errorCode : 'IMPORT_PROCESSING_FAILED';
            $job->forceFill([
                'status' => 'failed',
                'failed_at' => now(),
                'failure_code' => $safeCode,
                'failure_message' => 'Import gagal diproses.',
            ])->save();
            $this->auditLogService->record('dictionary.import_failed', $job, $actor, null, ['failure_code' => $safeCode]);

            if ($e instanceof ApiException) {
                throw $e;
            }

            Log::error('Dictionary import processing failed.', [
                'import_job_id' => $job->id,
                'exception_class' => $e::class,
                'exception_message' => $e->getMessage(),
                'exception' => $e,
            ]);

            throw new ApiException('Import gagal diproses.', 'IMPORT_PROCESSING_FAILED', 500, previous: $e);
        } finally {
            if (is_array($analysis ?? null)) {
                $this->fileService->cleanupDirectory($analysis['zip_temp_dir'] ?? null);
            }
        }
    }

    private function processCombinedWorkbook(DictionaryImportJob $job, $actor, array $analysis): DictionaryImportJob
    {
        $mediaByFilename = [];
        $vocabInserted = 0;
        $vocabUpdated = 0;
        $vocabSkipped = 0;
        $processedIndoKeys = [];
        $entryIdByIndonesia = [];
        $chunkSize = max(1, (int) config('dictionary.chunk_size'));

        foreach (array_chunk($analysis['rows']['vocabulary'], $chunkSize) as $chunk) {
            DB::transaction(function () use ($chunk, $job, $actor, &$mediaByFilename, &$vocabInserted, &$vocabUpdated, &$vocabSkipped, &$processedIndoKeys, &$entryIdByIndonesia, $analysis): void {
                foreach ($chunk as $row) {
                    $mergeKey = $row['merge_key'];

                    if (isset($processedIndoKeys[$mergeKey])) {
                        $vocabSkipped++;

                        continue;
                    }

                    $processedIndoKeys[$mergeKey] = true;
                    $data = $row['data'];
                    $existing = DictionaryEntry::query()->whereKey($row['existing_id'])->first();

                    if ($existing && $job->duplicate_strategy === 'skip') {
                        $vocabSkipped++;
                        $entryIdByIndonesia[$mergeKey] = $existing->id;

                        continue;
                    }

                    $audioMediaId = null;
                    if (($data['audio_filename'] ?? '') !== '' && isset($analysis['zip_files'][$data['audio_filename']])) {
                        $audioMediaId = $mediaByFilename[$data['audio_filename']] ??= $this->createAudioMedia($job, $actor, $data['audio_filename'], $analysis['zip_files'][$data['audio_filename']]['path']);
                    }

                    if ($existing && $job->duplicate_strategy === 'update') {
                        $existing->fill($this->progressiveEntryPayload($existing, $data, $row['category_id'], $audioMediaId) + [
                            'updated_by' => $actor->id,
                            'source_import_job_id' => $job->id,
                        ])->save();
                        $vocabUpdated++;
                        $entryIdByIndonesia[$mergeKey] = $existing->id;

                        continue;
                    }

                    if (! $existing) {
                        $entry = DictionaryEntry::query()->create($this->dictionaryEntryService->payload([
                            'category_id' => $row['category_id'],
                            'code' => $data['kode'],
                            'indonesia' => $data['indonesia'],
                            'english' => $data['english'],
                            'mekongga' => $data['mekongga'],
                            'example_mekongga' => null,
                            'example_indonesia' => null,
                            'audio_media_id' => $audioMediaId,
                            'status' => 'active',
                        ]) + [
                            'created_by' => $actor->id,
                            'source_import_job_id' => $job->id,
                        ]);
                        $vocabInserted++;
                        $entryIdByIndonesia[$mergeKey] = $entry->id;

                        continue;
                    }

                    $entryIdByIndonesia[$mergeKey] = $existing->id;
                }
            });
        }

        $sentenceInserted = 0;
        $sentenceUpdated = 0;
        $sentenceSkipped = 0;
        $processedPairs = [];

        foreach (array_chunk($analysis['rows']['sentence_examples'], $chunkSize) as $chunk) {
            DB::transaction(function () use ($chunk, $job, $actor, &$mediaByFilename, &$sentenceInserted, &$sentenceUpdated, &$sentenceSkipped, &$processedPairs, $entryIdByIndonesia, $analysis): void {
                foreach ($chunk as $row) {
                    if (isset($processedPairs[$row['pair_key']])) {
                        $sentenceSkipped++;

                        continue;
                    }

                    $entryId = $row['entry_id'] ?? ($row['pending_vocab_indonesia'] !== null ? ($entryIdByIndonesia[$row['pending_vocab_indonesia']] ?? null) : null);

                    if ($entryId === null) {
                        $sentenceSkipped++;

                        continue;
                    }

                    $processedPairs[$row['pair_key']] = true;
                    $data = $row['data'];
                    $sentenceKey = app(DictionaryNormalizer::class)->normalize($data['contoh_indonesia'] ?? '');
                    $existing = DictionarySentenceExample::query()
                        ->where('dictionary_entry_id', $entryId)
                        ->where('example_indonesia_normalized', $sentenceKey)
                        ->first();

                    if ($existing && $job->duplicate_strategy !== 'update') {
                        $sentenceSkipped++;

                        continue;
                    }

                    $audioMediaId = null;
                    if (($data['audio_filename'] ?? '') !== '' && isset($analysis['zip_files'][$data['audio_filename']])) {
                        $audioMediaId = $mediaByFilename[$data['audio_filename']] ??= $this->createAudioMedia($job, $actor, $data['audio_filename'], $analysis['zip_files'][$data['audio_filename']]['path']);
                    }

                    if ($existing && $job->duplicate_strategy === 'update') {
                        $existing->fill($this->progressiveSentencePayload($existing, $data, $entryId, $audioMediaId) + [
                            'updated_by' => $actor->id,
                            'source_import_job_id' => $job->id,
                        ])->save();
                        $sentenceUpdated++;

                        continue;
                    }

                    if (! $existing) {
                        try {
                            DB::transaction(fn () => DictionarySentenceExample::query()->create($this->sentencePayload($data, $entryId, $audioMediaId) + [
                                'created_by' => $actor->id,
                                'source_import_job_id' => $job->id,
                            ]));
                            $sentenceInserted++;
                        } catch (UniqueConstraintViolationException $e) {
                            $existing = DictionarySentenceExample::query()
                                ->where('dictionary_entry_id', $entryId)
                                ->where('example_indonesia_normalized', $sentenceKey)
                                ->first();

                            if (! $existing) {
                                throw $e;
                            }

                            if ($job->duplicate_strategy === 'update') {
                                $existing->fill($this->progressiveSentencePayload($existing, $data, $entryId, $audioMediaId) + [
                                    'updated_by' => $actor->id,
                                    'source_import_job_id' => $job->id,
                                ])->save();
                                $sentenceUpdated++;
                            } else {
                                $sentenceSkipped++;
                            }
                        }
                    }
                }
            });
        }

        $status = $analysis['summary']['invalid_rows'] > 0 ? 'completed_with_errors' : 'completed';
        $job->forceFill([
            'status' => $status,
            'inserted_rows' => $vocabInserted + $sentenceInserted,
            'updated_rows' => $vocabUpdated + $sentenceUpdated,
            'skipped_rows' => $vocabSkipped + $sentenceSkipped,
            'summary' => array_merge($this->withAudioResult((array) $job->summary, count($mediaByFilename)), [
                'vocabulary_result' => [
                    'inserted' => $vocabInserted,
                    'updated' => $vocabUpdated,
                    'skipped' => $vocabSkipped,
                ],
                'sentence_examples_result' => [
                    'inserted' => $sentenceInserted,
                    'updated' => $sentenceUpdated,
                    'skipped' => $sentenceSkipped,
                ],
            ]),
            'completed_at' => now(),
        ])->save();

        $this->auditLogService->record(
            $status === 'completed' ? 'dictionary.import_completed' : 'dictionary.import_completed_with_errors',
            $job,
            $actor,
            null,
            $job->only(['status', 'inserted_rows', 'updated_rows', 'skipped_rows']),
        );

        return $job->refresh();
    }

    private function progressiveEntryPayload(DictionaryEntry $existing, array $data, ?string $categoryId, ?string $audioMediaId): array
    {
        $merged = $existing->only(['category_id', 'indonesia', 'english', 'mekongga', 'example_mekongga', 'example_indonesia', 'audio_media_id', 'status']);

        if ($categoryId !== null) {
            $merged['category_id'] = $categoryId;
        }

        foreach (['indonesia', 'english', 'mekongga'] as $field) {
            if (($data[$field] ?? '') !== '') {
                $merged[$field] = $data[$field];
            }
        }

        $merged['audio_media_id'] = $audioMediaId ?? $merged['audio_media_id'];
        $merged['status'] = 'active';

        return $this->dictionaryEntryService->payload($merged);
    }

    private function sentencePayload(array $data, string $entryId, ?string $audioMediaId): array
    {
        return [
            'dictionary_entry_id' => $entryId,
            'code' => $data['kode'],
            'example_mekongga' => $data['contoh_mekongga'],
            'example_indonesia' => $data['contoh_indonesia'],
            'example_mekongga_normalized' => app(DictionaryNormalizer::class)->normalize($data['contoh_mekongga']),
            'example_indonesia_normalized' => app(DictionaryNormalizer::class)->normalize($data['contoh_indonesia']),
            'audio_media_id' => $audioMediaId,
            'status' => 'active',
        ];
    }

    private function progressiveSentencePayload(DictionarySentenceExample $existing, array $data, string $entryId, ?string $audioMediaId): array
    {
        $payload = [
            'dictionary_entry_id' => $entryId,
            'example_mekongga' => ($data['contoh_mekongga'] ?? '') !== '' ? $data['contoh_mekongga'] : $existing->example_mekongga,
            'example_indonesia' => ($data['contoh_indonesia'] ?? '') !== '' ? $data['contoh_indonesia'] : $existing->example_indonesia,
            'example_mekongga_normalized' => ($data['contoh_mekongga'] ?? '') !== '' ? app(DictionaryNormalizer::class)->normalize($data['contoh_mekongga']) : $existing->example_mekongga_normalized,
            'example_indonesia_normalized' => ($data['contoh_indonesia'] ?? '') !== '' ? app(DictionaryNormalizer::class)->normalize($data['contoh_indonesia']) : $existing->example_indonesia_normalized,
            'audio_media_id' => $audioMediaId ?? $existing->audio_media_id,
            'status' => 'active',
        ];

        if (($data['kode'] ?? '') !== '') {
            $payload['code'] = $data['kode'];
        }

        return $payload;
    }

    private function processSentenceExamples(DictionaryImportJob $job, $actor, array $analysis): DictionaryImportJob
    {
        $inserted = 0;
        $updated = 0;
        $skipped = 0;
        $processedPairs = [];
        $chunkSize = max(1, (int) config('dictionary.chunk_size'));

        foreach (array_chunk($analysis['rows'], $chunkSize) as $chunk) {
            DB::transaction(function () use ($chunk, $job, $actor, &$inserted, &$updated, &$skipped, &$processedPairs): void {
                foreach ($chunk as $row) {
                    if (isset($processedPairs[$row['pair_key']])) {
                        $skipped++;

                        continue;
                    }

                    $processedPairs[$row['pair_key']] = true;
                    $data = $row['data'];
                    $existing = DictionarySentenceExample::query()->whereKey($row['existing_id'])->first();
                    $payload = [
                        'dictionary_entry_id' => $row['entry_id'],
                        'code' => $data['kode'],
                        'example_mekongga' => $data['contoh_mekongga'],
                        'example_indonesia' => $data['contoh_indonesia'],
                        'example_mekongga_normalized' => app(DictionaryNormalizer::class)->normalize($data['contoh_mekongga']),
                        'example_indonesia_normalized' => app(DictionaryNormalizer::class)->normalize($data['contoh_indonesia']),
                        'status' => 'active',
                    ];

                    if ($existing && $job->duplicate_strategy === 'skip') {
                        $skipped++;

                        continue;
                    }

                    if ($existing && $job->duplicate_strategy === 'update') {
                        $existing->fill($payload + [
                            'updated_by' => $actor->id,
                            'source_import_job_id' => $job->id,
                        ])->save();
                        $updated++;

                        continue;
                    }

                    if (! $existing) {
                        DictionarySentenceExample::query()->create($payload + [
                            'created_by' => $actor->id,
                            'source_import_job_id' => $job->id,
                        ]);
                        $inserted++;
                    }
                }
            });
        }

        $status = $job->invalid_rows > 0 ? 'completed_with_errors' : 'completed';
        $job->forceFill([
            'status' => $status,
            'inserted_rows' => $inserted,
            'updated_rows' => $updated,
            'skipped_rows' => $skipped,
            'completed_at' => now(),
        ])->save();

        $this->auditLogService->record(
            $status === 'completed' ? 'dictionary.import_completed' : 'dictionary.import_completed_with_errors',
            $job,
            $actor,
            null,
            $job->only(['status', 'inserted_rows', 'updated_rows', 'skipped_rows']),
        );

        return $job->refresh();
    }

    private function withAudioResult(array $summary, int $installed): array
    {
        if (isset($summary['audio'])) {
            $summary['audio']['installed'] = $installed;
            $summary['audio']['result'] = $installed > 0 ? 'installed' : 'none';
        }

        return $summary;
    }

    private function createAudioMedia(DictionaryImportJob $job, $actor, string $filename, string $path): string
    {
        $uploadedFile = new UploadedFile($path, $filename, mime_content_type($path) ?: 'audio/mpeg', null, true);
        $media = $this->mediaUploadService->upload($actor, $uploadedFile, 'audio', 'public', [
            'dictionary_import_job_id' => $job->id,
            'audio_filename' => $filename,
        ], Request::create('/internal/dictionary-import'));

        return $media instanceof MediaFile ? $media->id : $media->getKey();
    }
}
