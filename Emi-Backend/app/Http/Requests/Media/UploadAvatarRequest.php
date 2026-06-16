<?php

namespace App\Http\Requests\Media;

use App\Http\Requests\ApiFormRequest;

class UploadAvatarRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'avatar' => ['required', 'file', 'max:'.(int) config('media.max_kb.image')],
        ];
    }
}
