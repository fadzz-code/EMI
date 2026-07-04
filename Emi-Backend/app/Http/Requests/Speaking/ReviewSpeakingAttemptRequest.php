<?php

namespace App\Http\Requests\Speaking;

use Illuminate\Foundation\Http\FormRequest;

class ReviewSpeakingAttemptRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->role === 'teacher';
    }

    public function rules(): array
    {
        return [
            'teacher_score' => ['required', 'numeric', 'min:0', 'max:100'],
            'teacher_feedback' => ['nullable', 'string', 'max:5000'],
        ];
    }
}
