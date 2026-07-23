<?php

namespace App\Http\Requests\Speaking;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ListSpeakingAttemptsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'],
            'analysis_status' => ['sometimes', Rule::in(['pending', 'processing', 'completed', 'failed'])],
            'review_status' => ['sometimes', Rule::in(['pending', 'reviewed'])],
            'search' => ['sometimes', 'string', 'max:100'],
            'sort' => ['sometimes', Rule::in(['created_at', 'updated_at'])],
            'direction' => ['sometimes', Rule::in(['asc', 'desc'])],
        ];
    }
}
