<?php

namespace App\Http\Requests\Dictionary;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class PreviewDictionaryImportRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'csv_file' => ['required', 'file', 'max:'.config('dictionary.max_csv_kb')],
            'audio_zip' => ['sometimes', 'file', 'max:'.config('dictionary.max_zip_kb')],
            'duplicate_strategy' => ['sometimes', Rule::in(['skip', 'update', 'reject'])],
            'csv_disk' => ['prohibited'],
            'csv_path' => ['prohibited'],
            'audio_zip_disk' => ['prohibited'],
            'audio_zip_path' => ['prohibited'],
        ];
    }
}
