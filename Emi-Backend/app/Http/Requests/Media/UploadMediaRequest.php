<?php

namespace App\Http\Requests\Media;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class UploadMediaRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'file' => ['required', 'file', 'max:'.(int) config('media.max_kb.audio')],
            'purpose' => ['required', Rule::in(config('media.purposes'))],
            'visibility' => ['required', Rule::in(config('media.visibilities'))],
            'metadata' => ['sometimes', 'array'],
            'uploaded_by' => ['prohibited'],
            'disk' => ['prohibited'],
            'path' => ['prohibited'],
            'stored_name' => ['prohibited'],
            'checksum' => ['prohibited'],
            'checksum_sha256' => ['prohibited'],
            'size_bytes' => ['prohibited'],
            'mime_type' => ['prohibited'],
            'deleted_by' => ['prohibited'],
        ];
    }
}
