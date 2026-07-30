<?php

namespace App\Http\Requests\Dictionary;

use App\Http\Requests\ApiFormRequest;

class DeleteDictionaryImportRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'confirm' => ['required', 'accepted'],
        ];
    }
}
