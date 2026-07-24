<?php

namespace App\Http\Requests\Teacher;

use App\Http\Requests\ApiFormRequest;

class ListRegistrationRequestsRequest extends ApiFormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'status' => 'nullable|in:pending,approved,rejected',
            'search' => 'nullable|string|max:255',
            'sort_by' => 'nullable|in:created_at,status',
            'sort_order' => 'nullable|in:asc,desc',
            'per_page' => 'nullable|integer|min:1|max:100',
        ];
    }
}
