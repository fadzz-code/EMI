<?php

namespace App\Http\Requests\PasswordReset;

use App\Http\Requests\ApiFormRequest;

class RejectPasswordResetRequest extends ApiFormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'review_note' => ['required', 'string', 'max:1000'],
        ];
    }
}
