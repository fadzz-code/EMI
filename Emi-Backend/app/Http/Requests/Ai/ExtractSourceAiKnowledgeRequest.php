<?php

namespace App\Http\Requests\Ai;

use Illuminate\Foundation\Http\FormRequest;

class ExtractSourceAiKnowledgeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() && $this->user()->role === 'admin';
    }

    public function rules(): array
    {
        return [
            'source_type' => ['required', 'string', 'in:link,pdf'],
            'source_url' => ['required', 'url', 'max:2048'],
        ];
    }
}
