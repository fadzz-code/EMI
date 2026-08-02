<?php

namespace App\Services;

use App\Exceptions\SpeakingAiException;
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
        if (! $media) {
            throw new SpeakingAiException('SPEAKING_AUDIO_RELATION_MISSING', 'Media audio speaking tidak ditemukan.');
        }

        if (! Storage::disk($media->disk)->exists($media->path)) {
            throw new SpeakingAiException('SPEAKING_AUDIO_FILE_MISSING', 'Audio speaking tidak ditemukan pada penyimpanan.');
        }

        $stream = Storage::disk($media->disk)->readStream($media->path);
        if ($stream === false) {
            throw new SpeakingAiException('SPEAKING_AUDIO_FILE_UNREADABLE', 'Audio speaking tidak dapat dibaca.');
        }

        $contentType = in_array($media->mime_type, ['video/mp4', 'application/mp4'], true)
            ? 'audio/mp4'
            : $media->mime_type;

        try {
            $response = Http::withToken((string) config('speaking.ai.token'))
                ->connectTimeout((int) config('speaking.ai.connect_timeout_seconds', 5))
                ->timeout((int) config('speaking.ai.timeout_seconds', 60))
                ->retry(2, 100, fn (Throwable $exception): bool => $exception instanceof ConnectionException
                    || ($exception instanceof RequestException && $exception->response->serverError()), false)
                ->attach('file', $stream, $media->original_name, ['Content-Type' => $contentType])
                ->post(rtrim((string) config('speaking.ai.base_url'), '/').'/predict', [
                    'target_text' => $attempt->target_text_snapshot,
                ]);
        } catch (ConnectionException) {
            throw new SpeakingAiException('SPEAKING_AI_UNAVAILABLE', 'Layanan analisis speaking tidak dapat dihubungi.');
        } catch (Throwable) {
            throw new RuntimeException('Analisis speaking AI gagal.');
        } finally {
            if (is_resource($stream)) {
                fclose($stream);
            }
        }

        if (! $response->successful()) {
            $upstreamCode = $response->json('code');
            [$code, $message] = match ($upstreamCode) {
                'SPEAKING_AI_UNAUTHORIZED' => ['SPEAKING_AI_UNAUTHORIZED', 'Autentikasi layanan analisis speaking gagal.'],
                'SPEAKING_AI_VALIDATION_ERROR' => ['SPEAKING_AI_INVALID_AUDIO', 'Audio speaking tidak dapat dianalisis.'],
                'SPEAKING_AI_TIMEOUT' => ['SPEAKING_AI_TIMEOUT', 'Layanan analisis speaking melewati batas waktu.'],
                'SPEAKING_AI_UNAVAILABLE' => ['SPEAKING_AI_UNAVAILABLE', 'Layanan analisis speaking sedang tidak tersedia.'],
                default => match ($response->status()) {
                    401, 403 => ['SPEAKING_AI_UNAUTHORIZED', 'Autentikasi layanan analisis speaking gagal.'],
                    408, 504 => ['SPEAKING_AI_TIMEOUT', 'Layanan analisis speaking melewati batas waktu.'],
                    422 => ['SPEAKING_AI_INVALID_AUDIO', 'Audio speaking tidak dapat dianalisis.'],
                    503 => ['SPEAKING_AI_UNAVAILABLE', 'Layanan analisis speaking sedang tidak tersedia.'],
                    default => ['SPEAKING_AI_RESPONSE_INVALID', 'Analisis speaking AI gagal.'],
                },
            };

            throw new SpeakingAiException($code, $message);
        }

        $result = $response->json();
        if (! is_array($result)
            || ! isset($result['transcription'], $result['score'], $result['alignment'])
            || ! is_string($result['transcription'])
            || ! is_numeric($result['score'])
            || ! is_array($result['alignment'])
            || (float) $result['score'] < 0
            || (float) $result['score'] > 100) {
            throw new SpeakingAiException('SPEAKING_AI_RESPONSE_INVALID', 'Respons layanan analisis speaking tidak valid.');
        }

        return $result;
    }
}
