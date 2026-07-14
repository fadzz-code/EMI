<?php

namespace App\Http\Requests\Auth;

use App\Http\Requests\ApiFormRequest;

class DeleteAccountRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'current_password' => ['required', 'string'],
        ];
    }
}
