<?php

namespace App\Http\Requests\Speaking;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreAdminSpeakingExerciseRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->role === 'admin';
    }

    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'prompt_text' => ['nullable', 'string', 'max:5000'],
            'target_text' => ['required', 'string', 'max:5000'],
            'target_translation' => ['nullable', 'string', 'max:5000'],
            'reference_audio_media_id' => ['nullable', 'uuid', Rule::exists('media_files', 'id')],
            'difficulty' => ['nullable', 'string', 'max:50'],
            'status' => ['nullable', Rule::in(['draft', 'published', 'archived'])],
            'metadata' => ['nullable', 'array'],
        ];
    }
}
