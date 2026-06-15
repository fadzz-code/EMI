<?php

namespace App\Http\Requests\Admin;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class ListRegistrationRequestsRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'status' => ['sometimes', Rule::in(['pending', 'approved', 'rejected'])],
            'requested_role' => ['sometimes', Rule::in(['teacher', 'student'])],
            'school_id' => ['sometimes', 'uuid', 'exists:schools,id'],
            'class_id' => ['sometimes', 'uuid', 'exists:classes,id'],
            'search' => ['sometimes', 'string', 'max:255'],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'],
            'sort_by' => ['sometimes', Rule::in(['created_at', 'updated_at', 'status', 'requested_role'])],
            'sort_direction' => ['sometimes', Rule::in(['asc', 'desc'])],
        ];
    }
}
