<?php

namespace App\Http\Requests\Admin;

use App\Http\Requests\ApiFormRequest;

class ApproveRegistrationRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'review_note' => ['sometimes', 'nullable', 'string', 'max:1000'],
        ];
    }
}
