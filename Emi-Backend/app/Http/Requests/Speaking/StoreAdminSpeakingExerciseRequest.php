<?php

namespace App\Http\Requests\Speaking;

use App\Models\MediaFile;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

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
            'reference_audio_media_id' => [
                'nullable',
                'uuid',
                Rule::exists('media_files', 'id')
                    ->where('purpose', 'speaking_reference_audio')
                    ->whereNull('deleted_at'),
            ],
            'difficulty' => ['nullable', 'string', 'max:50'],
            'status' => ['nullable', Rule::in(['draft', 'published'])],
            'metadata' => ['nullable', 'array'],
        ];
    }

    public function after(): array
    {
        return [function (Validator $validator): void {
            if ($this->filled('reference_audio_media_id')) {
                $media = MediaFile::query()->find($this->input('reference_audio_media_id'));

                if ($media && ! str_starts_with($media->mime_type, 'audio/')) {
                    $validator->errors()->add('reference_audio_media_id', 'Media referensi harus berupa audio.');
                }
            }

            if ($this->input('status') !== 'published') {
                return;
            }

            $exercise = $this->route('exercise');
            $title = $this->exists('title') ? $this->input('title') : $exercise?->title;
            $target = $this->exists('target_text') ? $this->input('target_text') : $exercise?->target_text;

            if (! is_string($title) || trim($title) === '') {
                $validator->errors()->add('title', 'Judul wajib diisi sebelum diterbitkan.');
            }

            if (! is_string($target) || trim($target) === '') {
                $validator->errors()->add('target_text', 'Target teks wajib diisi sebelum diterbitkan.');
            }
        }];
    }
}
