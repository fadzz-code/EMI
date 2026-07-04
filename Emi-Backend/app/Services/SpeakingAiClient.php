<?php

namespace App\Services;

use App\Models\SpeakingAttempt;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use RuntimeException;

class SpeakingAiClient
{
    public function enabled(): bool
    {
        return (bool) config('speaking.ai.enabled', false);
    }

    public function analyze(SpeakingAttempt $attempt): array
    {
        if (! $this->enabled()) {
            throw new RuntimeException('Layanan AI speaking belum diaktifkan.');
        }

        $media = $attempt->audioMedia;
        if (! $media || ! Storage::disk($media->disk)->exists($media->path)) {
            throw new RuntimeException('Audio speaking tidak ditemukan.');
        }

        $stream = Storage::disk($media->disk)->readStream($media->path);
        if ($stream === false) {
            throw new RuntimeException('Audio speaking tidak dapat dibaca.');
        }

        try {
            $response = Http::timeout((int) config('speaking.ai.timeout_seconds', 60))
                ->attach('file', $stream, $media->original_name, ['Content-Type' => $media->mime_type])
                ->post(rtrim((string) config('speaking.ai.base_url'), '/').'/predict', [
                    'target_text' => $attempt->target_text_snapshot,
                ]);
        } finally {
            if (is_resource($stream)) {
                fclose($stream);
            }
        }

        if (! $response->successful()) {
            $message = $response->json('error') ?: 'Analisis speaking AI gagal.';
            throw new RuntimeException($message);
        }

        return $response->json();
    }
}
