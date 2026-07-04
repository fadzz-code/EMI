<?php

namespace App\Http\Requests\Speaking;

use Illuminate\Foundation\Http\FormRequest;

class StoreSpeakingAttemptRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->role === 'student';
    }

    public function rules(): array
    {
        $maxKb = (int) config('speaking.max_audio_mb', 5) * 1024;

        return [
            'file' => ['required', 'file', 'max:'.$maxKb, 'mimetypes:audio/mpeg,audio/wav,audio/x-wav,audio/mp4,audio/ogg,audio/webm'],
            'audio_duration_seconds' => ['nullable', 'integer', 'min:1', 'max:'.(int) config('speaking.max_duration_seconds', 30)],
        ];
    }
}
