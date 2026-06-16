<?php

namespace App\Http\Requests\Dictionary;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class UpdateDictionaryEntryRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'category_id' => ['sometimes', 'uuid', 'exists:dictionary_categories,id'],
            'indonesia' => ['sometimes', 'string', 'max:255'],
            'english' => ['sometimes', 'string', 'max:255'],
            'mekongga' => ['sometimes', 'string', 'max:255'],
            'example_mekongga' => ['nullable', 'string'],
            'example_indonesia' => ['nullable', 'string'],
            'audio_media_id' => ['nullable', 'uuid', 'exists:media_files,id'],
            'status' => ['sometimes', Rule::in(['active', 'inactive'])],
            'indonesia_normalized' => ['prohibited'],
            'english_normalized' => ['prohibited'],
            'mekongga_normalized' => ['prohibited'],
            'created_by' => ['prohibited'],
            'updated_by' => ['prohibited'],
        ];
    }
}
