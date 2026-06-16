<?php

namespace App\Http\Requests\Dictionary;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class ListDictionaryImportsRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'status' => ['sometimes', Rule::in(['previewing', 'preview_ready', 'queued', 'processing', 'completed', 'completed_with_errors', 'failed'])],
            'duplicate_strategy' => ['sometimes', Rule::in(['skip', 'update', 'reject'])],
            'uploaded_by' => ['sometimes', 'uuid', 'exists:users,id'],
            'date_from' => ['sometimes', 'date'],
            'date_to' => ['sometimes', 'date'],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'],
        ];
    }
}
