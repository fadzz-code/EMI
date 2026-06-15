<?php

namespace App\Http\Requests\UserManagement;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class UpdateUserStatusRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'status' => ['required', Rule::in(['approved', 'inactive'])],
            'reason' => ['required_if:status,inactive', 'nullable', 'string', 'max:1000'],
        ];
    }
}
