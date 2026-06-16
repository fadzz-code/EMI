<?php

namespace Database\Factories;

use App\Models\MediaFile;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/** @extends Factory<MediaFile> */
class MediaFileFactory extends Factory
{
    protected $model = MediaFile::class;

    public function definition(): array
    {
        $id = (string) Str::uuid();

        return [
            'uploaded_by' => User::factory()->admin(),
            'purpose' => 'document',
            'original_name' => 'materi.pdf',
            'stored_name' => "{$id}.pdf",
            'disk' => config('media.private_disk', 'local'),
            'path' => "media/document/2026/06/{$id}/{$id}.pdf",
            'mime_type' => 'application/pdf',
            'extension' => 'pdf',
            'size_bytes' => 1024,
            'checksum_sha256' => hash('sha256', $id),
            'visibility' => 'private',
            'metadata' => [],
        ];
    }

    public function public(): static
    {
        return $this->state(fn (): array => [
            'visibility' => 'public',
            'disk' => config('media.public_disk', 'public'),
        ]);
    }

    public function private(): static
    {
        return $this->state(fn (): array => [
            'visibility' => 'private',
            'disk' => config('media.private_disk', 'local'),
        ]);
    }

    public function avatar(): static
    {
        return $this->public()->state(fn (): array => [
            'purpose' => 'avatar',
            'original_name' => 'avatar.jpg',
            'mime_type' => 'image/jpeg',
            'extension' => 'jpg',
        ]);
    }

    public function lessonImage(): static
    {
        return $this->public()->state(fn (): array => [
            'purpose' => 'lesson_image',
            'original_name' => 'lesson.jpg',
            'mime_type' => 'image/jpeg',
            'extension' => 'jpg',
        ]);
    }

    public function audio(): static
    {
        return $this->public()->state(fn (): array => [
            'purpose' => 'audio',
            'original_name' => 'lesson.mp3',
            'mime_type' => 'audio/mpeg',
            'extension' => 'mp3',
        ]);
    }

    public function speakingRecording(): static
    {
        return $this->private()->state(fn (): array => [
            'purpose' => 'speaking_recording',
            'original_name' => 'recording.mp3',
            'mime_type' => 'audio/mpeg',
            'extension' => 'mp3',
        ]);
    }
}
