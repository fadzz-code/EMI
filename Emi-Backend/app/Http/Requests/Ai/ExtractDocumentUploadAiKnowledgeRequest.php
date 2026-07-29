<?php

namespace App\Http\Requests\Ai;

use Illuminate\Foundation\Http\FormRequest;

class ExtractDocumentUploadAiKnowledgeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() && $this->user()->role === 'admin';
    }

    public function rules(): array
    {
        return [
            'file' => ['required', 'file', 'mimes:docx,txt', 'max:10240'],
        ];
    }
}
