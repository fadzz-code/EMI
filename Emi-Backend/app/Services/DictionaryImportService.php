<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Jobs\ProcessDictionaryImport;
use App\Models\DictionaryImportJob;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DictionaryImportService
{
    public function __construct(
        private readonly AuditLogService $auditLogService,
        private readonly DictionaryImportFileService $fileService,
    ) {}

    public function confirm(DictionaryImportJob $job, User $admin, Request $request): DictionaryImportJob
    {
        $dispatch = false;

        $job = DB::transaction(function () use ($job, $admin, $request, &$dispatch) {
            $job = DictionaryImportJob::query()->whereKey($job->id)->lockForUpdate()->firstOrFail();

            if (in_array($job->status, ['queued', 'processing', 'completed', 'completed_with_errors'], true)) {
                return $job;
            }

            if ($job->status !== 'preview_ready') {
                throw new ApiException('Status import tidak valid untuk konfirmasi.', 'INVALID_IMPORT_STATUS', 409);
            }

            if ($job->valid_rows < 1) {
                throw new ApiException('Import tidak memiliki baris valid.', 'IMPORT_HAS_NO_VALID_ROWS', 409);
            }

            $job->forceFill(['status' => 'queued'])->save();
            $dispatch = true;

            $this->auditLogService->record('dictionary.import_queued', $job, $admin, ['status' => 'preview_ready'], ['status' => 'queued'], [], $request);

            return $job;
        });

        if ($dispatch) {
            ProcessDictionaryImport::dispatch($job->id);
        }

        return $job->refresh();
    }

    public function deleteHistory(DictionaryImportJob $job, User $admin, Request $request): void
    {
        DB::transaction(function () use ($job, $admin, $request): void {
            $locked = DictionaryImportJob::query()->whereKey($job->id)->lockForUpdate()->firstOrFail();
            $this->ensureInactive($locked);
            $this->auditLogService->record('dictionary.import_history_deleted', $locked, $admin, $locked->only(['status']), null, [], $request);
            $locked->errors()->delete();
            $locked->delete();
        });
        $this->fileService->deleteImportDirectory($job->id);
    }

    public function deleteError(DictionaryImportJob $job, string $errorId, User $admin, Request $request): void
    {
        DB::transaction(function () use ($job, $errorId, $admin, $request): void {
            $locked = DictionaryImportJob::query()->whereKey($job->id)->lockForUpdate()->firstOrFail();
            $this->ensureInactive($locked);
            $error = $locked->errors()->whereKey($errorId)->lockForUpdate()->firstOrFail();
            $this->auditLogService->record('dictionary.import_error_deleted', $locked, $admin, ['error_id' => $error->id], null, [], $request);
            $error->delete();
        });
    }

    public function deleteErrors(DictionaryImportJob $job, User $admin, Request $request): int
    {
        return DB::transaction(function () use ($job, $admin, $request): int {
            $locked = DictionaryImportJob::query()->whereKey($job->id)->lockForUpdate()->firstOrFail();
            $this->ensureInactive($locked);
            $count = $locked->errors()->count();
            $locked->errors()->delete();
            $this->auditLogService->record('dictionary.import_errors_deleted', $locked, $admin, ['count' => $count], null, [], $request);

            return $count;
        });
    }

    private function ensureInactive(DictionaryImportJob $job): void
    {
        if (in_array($job->status, ['previewing', 'queued', 'processing'], true)) {
            throw new ApiException('Import aktif tidak dapat diubah.', 'ACTIVE_IMPORT_CANNOT_BE_DELETED', 409);
        }
    }
}
