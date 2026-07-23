<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SpeakingAttemptResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'exercise_id' => $this->speaking_exercise_id,
            'target_text' => $this->target_text_snapshot,
            'status' => $this->status,
            'analysis_status' => $this->analysis_status,
            'review_status' => $this->review_status,
            'analysis' => [
                'status' => $this->analysis_status,
                'engine' => $this->ai_engine,
                'model' => $this->ai_model,
                'score' => $this->ai_score !== null ? (float) $this->ai_score : null,
                'transcription' => $this->ai_transcription,
                'alignment' => $this->ai_alignment,
                'error' => $this->ai_error,
            ],
            'review' => [
                'status' => $this->review_status,
                'score' => $this->teacher_score !== null ? (float) $this->teacher_score : null,
                'feedback' => $this->teacher_feedback,
                'reviewed_at' => $this->reviewed_at?->toISOString(),
                'reviewer' => $this->whenLoaded('reviewer', fn () => $this->reviewer ? [
                    'id' => $this->reviewer->id,
                    'full_name' => $this->reviewer->full_name,
                ] : null),
            ],
            'ai_score' => $this->ai_score !== null ? (float) $this->ai_score : null,
            'ai_transcription' => $this->ai_transcription,
            'ai_alignment' => $this->ai_alignment,
            'ai_warnings' => array_values(array_filter(
                is_array($this->ai_raw_response['warnings'] ?? null) ? $this->ai_raw_response['warnings'] : [],
                fn ($warning) => is_string($warning)
            )),
            'ai_error' => $this->ai_error,
            'ai_error_code' => $this->ai_raw_response['error_code'] ?? null,
            'teacher_score' => $this->teacher_score !== null ? (float) $this->teacher_score : null,
            'teacher_feedback' => $this->teacher_feedback,
            'reviewed_at' => $this->reviewed_at?->toISOString(),
            'audio_media_id' => $this->audio_media_id,
            'capture_source' => $this->capture_source,
            'audio_url' => $this->audio_media_id ? '/api/v1/media/'.$this->audio_media_id : null,
            'temporary_url_endpoint' => $this->audio_media_id ? '/api/v1/media/'.$this->audio_media_id.'/temporary-url' : null,
            'recording' => [
                'media_id' => $this->audio_media_id,
                'capture_source' => $this->capture_source,
                'mime_type' => $this->audio_mime_type,
                'size_bytes' => $this->audio_size_bytes,
                'duration_seconds' => $this->audio_duration_seconds,
                'temporary_url_endpoint' => $this->audio_media_id ? '/api/v1/media/'.$this->audio_media_id.'/temporary-url' : null,
            ],
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
            'exercise' => $this->whenLoaded('exercise', fn () => new SpeakingExerciseResource($this->exercise)),
            'student' => $this->whenLoaded('student', fn () => [
                'id' => $this->student->id,
                'full_name' => $this->student->full_name,
                'email' => $this->student->email,
            ]),
        ];
    }
}
