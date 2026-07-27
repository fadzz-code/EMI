<?php

namespace App\Http\Requests\Ai;

use App\Http\Requests\ApiFormRequest;
use Illuminate\Validation\Rule;

class ListChatbotConversationsRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'status' => ['sometimes', 'nullable', Rule::in(['active', 'archived'])],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:50'],
        ];
    }
}
