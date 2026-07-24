<?php

namespace App\Http\Requests\Teacher;

use App\Http\Requests\ApiFormRequest;

class ApproveRegistrationRequest extends ApiFormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'review_note' => 'nullable|string|max:1000',
        ];
    }
}
