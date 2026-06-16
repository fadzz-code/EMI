<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DictionaryImportJobResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'status' => $this->status,
            'duplicate_strategy' => $this->duplicate_strategy,
            'csv_original_name' => $this->csv_original_name,
            'csv_size_bytes' => $this->csv_size_bytes,
            'audio_zip_original_name' => $this->audio_zip_original_name,
            'audio_zip_size_bytes' => $this->audio_zip_size_bytes,
            'total_rows' => $this->total_rows,
            'valid_rows' => $this->valid_rows,
            'invalid_rows' => $this->invalid_rows,
            'inserted_rows' => $this->inserted_rows,
            'updated_rows' => $this->updated_rows,
            'skipped_rows' => $this->skipped_rows,
            'warning_count' => $this->warning_count,
            'summary' => $this->summary,
            'failure_code' => $this->failure_code,
            'failure_message' => $this->failure_message,
            'started_at' => $this->started_at?->toISOString(),
            'completed_at' => $this->completed_at?->toISOString(),
            'failed_at' => $this->failed_at?->toISOString(),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
