<?php

namespace App\Jobs;

use App\Services\DictionaryImportProcessingService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class ProcessDictionaryImport implements ShouldQueue
{
    use Queueable;

    public int $tries = 3;

    public function __construct(public string $importJobId) {}

    public function backoff(): array
    {
        return [10, 60, 180];
    }

    public function handle(DictionaryImportProcessingService $processingService): void
    {
        $processingService->process($this->importJobId);
    }
}
