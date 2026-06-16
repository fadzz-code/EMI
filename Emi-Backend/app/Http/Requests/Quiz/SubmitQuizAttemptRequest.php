<?php

namespace App\Http\Requests\Quiz;

use App\Http\Requests\ApiFormRequest;

class SubmitQuizAttemptRequest extends ApiFormRequest
{
    protected function prepareForValidation(): void
    {
        $this->merge(['idempotency_key' => $this->header('Idempotency-Key')]);
    }

    public function rules(): array
    {
        return [
            'idempotency_key' => ['required', 'string', 'min:16', 'max:128'],
        ];
    }
}
