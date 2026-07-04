<?php

namespace App\Http\Requests\Ai;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ImportPdfAiKnowledgeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() && $this->user()->role === 'admin';
    }

    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'category' => ['nullable', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'file' => ['required', 'file', 'mimes:pdf', 'max:10240'],
            'status' => ['nullable', Rule::in(['draft', 'published'])],
        ];
    }
}
