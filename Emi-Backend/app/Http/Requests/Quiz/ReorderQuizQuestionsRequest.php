<?php

namespace App\Http\Requests\Quiz;

use App\Http\Requests\ApiFormRequest;

class ReorderQuizQuestionsRequest extends ApiFormRequest
{
    public function rules(): array
    {
        return [
            'question_ids' => ['required', 'array', 'min:1'],
            'question_ids.*' => ['required', 'uuid', 'distinct'],
        ];
    }
}
