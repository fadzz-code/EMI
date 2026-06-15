<?php

namespace App\Http\Requests\Admin;

use App\Http\Requests\ApiFormRequest;

class RejectRegistrationRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'review_note' => ['required', 'string', 'max:1000'],
        ];
    }
}
