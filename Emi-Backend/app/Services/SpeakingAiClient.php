<?php

namespace App\Services;

use App\Models\SpeakingAttempt;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Client\RequestException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use RuntimeException;
use Throwable;

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
            $response = Http::withToken((string) config('speaking.ai.token'))
                ->connectTimeout((int) config('speaking.ai.connect_timeout_seconds', 5))
                ->timeout((int) config('speaking.ai.timeout_seconds', 60))
                ->retry(2, 100, fn (Throwable $exception): bool => $exception instanceof ConnectionException
                    || ($exception instanceof RequestException && $exception->response->serverError()), false)
                ->attach('file', $stream, $media->original_name, ['Content-Type' => $media->mime_type])
                ->post(rtrim((string) config('speaking.ai.base_url'), '/').'/predict', [
                    'target_text' => $attempt->target_text_snapshot,
                ]);
        } catch (Throwable) {
            throw new RuntimeException('Analisis speaking AI gagal.');
        } finally {
            if (is_resource($stream)) {
                fclose($stream);
            }
        }

        if (! $response->successful()) {
            throw new RuntimeException('Analisis speaking AI gagal.');
        }

        $result = $response->json();
        if (! is_array($result)
            || ! isset($result['transcription'], $result['score'], $result['alignment'])
            || ! is_string($result['transcription'])
            || ! is_numeric($result['score'])
            || ! is_array($result['alignment'])
            || (float) $result['score'] < 0
            || (float) $result['score'] > 100) {
            throw new RuntimeException('Analisis speaking AI gagal.');
        }

        return $result;
    }
}
