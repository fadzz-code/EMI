<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DictionaryImportErrorResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'row_number' => $this->row_number,
            'field' => $this->field,
            'code' => $this->code,
            'message' => $this->message,
            'raw_data' => $this->raw_data,
            'created_at' => $this->created_at?->toISOString(),
        ];
    }
}
