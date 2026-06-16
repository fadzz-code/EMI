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
    public function __construct(private readonly AuditLogService $auditLogService) {}

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
}
