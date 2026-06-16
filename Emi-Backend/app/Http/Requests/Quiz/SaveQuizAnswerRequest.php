<?php

namespace App\Http\Requests\Quiz;

use App\Http\Requests\ApiFormRequest;

class SaveQuizAnswerRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'selected_option_id' => ['nullable', 'uuid'],
            'answer_text' => ['nullable', 'string'],
        ];
    }
}
