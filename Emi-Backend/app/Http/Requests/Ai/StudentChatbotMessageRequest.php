<?php

namespace App\Http\Requests\Ai;

use App\Http\Requests\ApiFormRequest;

class StudentChatbotMessageRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'message' => ['required', 'string', 'min:2', 'max:1000'],
        ];
    }
}
