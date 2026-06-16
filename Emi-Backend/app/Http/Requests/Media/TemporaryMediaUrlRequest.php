<?php

namespace App\Http\Requests\Media;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class TemporaryMediaUrlRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'expires_in_minutes' => ['sometimes', 'integer', 'min:1', 'max:60'],
            'disposition' => ['sometimes', Rule::in(['inline', 'attachment'])],
            'path' => ['prohibited'],
            'disk' => ['prohibited'],
        ];
    }
}
