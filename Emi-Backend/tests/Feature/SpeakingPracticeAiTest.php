<?php

namespace Tests\Feature;

use App\Models\MediaFile;
use App\Models\SchoolClass;
use App\Models\SpeakingAttempt;
use App\Models\SpeakingExercise;
use App\Models\StudentClassMembership;
use App\Models\TeacherClassAssignment;
use App\Models\User;
use App\Services\SpeakingAiClient;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use RuntimeException;
use Tests\TestCase;

class SpeakingPracticeAiTest extends TestCase
{
    use RefreshDatabase;

    public function test_student_can_list_published_speaking_exercises(): void
    {
        [$student, , $class] = $this->classroomUsers();
        $published = $this->exercise($class, ['title' => 'Salam dasar']);
        $this->exercise($class, ['title' => 'Draft', 'status' => 'draft']);

        $this->withToken($this->tokenFor($student))->getJson('/api/v1/student/speaking/exercises')
            ->assertOk()
            ->assertJsonPath('data.0.id', $published->id)
            ->assertJsonCount(1, 'data');
    }

    public function test_student_can_submit_audio_attempt_and_fake_ai_result_is_stored(): void
    {
        Storage::fake('local');
        config(['speaking.ai.enabled' => true]);
        $this->bindSpeakingAiSuccess();
        [$student, , $class] = $this->classroomUsers();
        $exercise = $this->exercise($class);

        $response = $this->withToken($this->tokenFor($student))->post('/api/v1/student/speaking/exercises/'.$exercise->id.'/attempts', [
            'file' => UploadedFile::fake()->create('recording.mp3', 128, 'audio/mpeg'),
            'audio_duration_seconds' => 5,
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.status', 'completed')
            ->assertJsonPath('data.ai_score', 82.5)
            ->assertJsonPath('data.ai_transcription', 'ari nggiro');

        $attempt = SpeakingAttempt::query()->firstOrFail();
        $this->assertNotNull($attempt->audio_media_id);
        $this->assertNotNull($attempt->audio_path);
        $this->assertDatabaseMissing('speaking_attempts', ['audio_path' => 'binary']);
        Storage::disk($attempt->audio_disk)->assertExists($attempt->audio_path);
        $this->assertSame(['0_ari' => 100], $attempt->ai_alignment);
    }

    public function test_student_can_upload_audio_webm_speaking_attempt(): void
    {
        Storage::fake('local');
        config(['speaking.ai.enabled' => true]);
        $this->bindSpeakingAiSuccess();
        [$student, , $class] = $this->classroomUsers();
        $exercise = $this->exercise($class);

        $response = $this->withToken($this->tokenFor($student))->post('/api/v1/student/speaking/exercises/'.$exercise->id.'/attempts', [
            'file' => UploadedFile::fake()->create('speaking-attempt.webm', 128, 'audio/webm'),
        ]);

        $response->assertCreated();

        $attempt = SpeakingAttempt::query()->firstOrFail();
        $this->assertSame('private', $attempt->audioMedia->visibility);
        $this->assertSame('speaking_recording', $attempt->audioMedia->purpose);
        $this->assertSame('local', $attempt->audioMedia->disk);
        $this->assertSame('webm', $attempt->audioMedia->extension);
        $this->assertDatabaseMissing('speaking_attempts', ['audio_path' => 'binary']);
        Storage::disk($attempt->audio_disk)->assertExists($attempt->audio_path);
    }

    public function test_student_can_upload_video_webm_speaking_attempt(): void
    {
        Storage::fake('local');
        config(['speaking.ai.enabled' => true]);
        $this->bindSpeakingAiSuccess();
        [$student, , $class] = $this->classroomUsers();
        $exercise = $this->exercise($class);

        $response = $this->withToken($this->tokenFor($student))->post('/api/v1/student/speaking/exercises/'.$exercise->id.'/attempts', [
            'file' => UploadedFile::fake()->create('speaking-attempt.webm', 128, 'video/webm'),
        ]);

        $response->assertCreated();
        $this->assertSame('webm', SpeakingAttempt::query()->firstOrFail()->audioMedia->extension);
    }

    public function test_ai_failure_marks_attempt_failed_and_stores_error(): void
    {
        Storage::fake('local');
        config(['speaking.ai.enabled' => true]);
        $this->bindSpeakingAiFailure();
        [$student, , $class] = $this->classroomUsers();
        $exercise = $this->exercise($class);

        $this->withToken($this->tokenFor($student))->post('/api/v1/student/speaking/exercises/'.$exercise->id.'/attempts', [
            'file' => UploadedFile::fake()->create('recording.mp3', 128, 'audio/mpeg'),
        ])->assertCreated()
            ->assertJsonPath('data.status', 'failed')
            ->assertJsonPath('data.ai_error', 'AI unavailable');
    }

    public function test_student_cannot_view_another_students_attempt(): void
    {
        [$student, , $class] = $this->classroomUsers();
        $other = User::factory()->student()->approved()->create();
        StudentClassMembership::factory()->create(['student_id' => $other->id, 'class_id' => $class->id, 'is_active' => true]);
        $attempt = $this->attemptFor($other, $this->exercise($class));

        $this->withToken($this->tokenFor($student))->getJson('/api/v1/student/speaking/attempts/'.$attempt->id)
            ->assertForbidden();
    }

    public function test_teacher_can_list_and_review_allowed_student_attempts(): void
    {
        [$student, $teacher, $class] = $this->classroomUsers();
        $attempt = $this->attemptFor($student, $this->exercise($class));

        $this->withToken($this->tokenFor($teacher))->getJson('/api/v1/teacher/speaking/attempts')
            ->assertOk()
            ->assertJsonPath('data.0.id', $attempt->id);

        $this->withToken($this->tokenFor($teacher))->patchJson('/api/v1/teacher/speaking/attempts/'.$attempt->id.'/feedback', [
            'teacher_score' => 85,
            'teacher_feedback' => 'Pengucapan sudah cukup jelas, ulangi bagian akhir.',
        ])->assertOk()
            ->assertJsonPath('data.status', 'reviewed')
            ->assertJsonPath('data.teacher_score', 85);

        $this->assertDatabaseHas('speaking_attempts', [
            'id' => $attempt->id,
            'reviewed_by_id' => $teacher->id,
            'status' => 'reviewed',
        ]);
    }

    public function test_teacher_cannot_access_unauthorized_attempt(): void
    {
        [$student, $teacher] = $this->classroomUsers();
        $otherClass = SchoolClass::factory()->create();
        $attempt = $this->attemptFor($student, $this->exercise($otherClass));

        $this->withToken($this->tokenFor($teacher))->getJson('/api/v1/teacher/speaking/attempts/'.$attempt->id)
            ->assertForbidden();
    }

    public function test_validation_rejects_oversized_or_invalid_audio(): void
    {
        Storage::fake('local');
        config(['speaking.max_audio_mb' => 1]);
        [$student, , $class] = $this->classroomUsers();
        $exercise = $this->exercise($class);

        $this->withToken($this->tokenFor($student))->post('/api/v1/student/speaking/exercises/'.$exercise->id.'/attempts', [
            'file' => UploadedFile::fake()->create('bad.txt', 10, 'text/plain'),
        ])->assertUnprocessable();

        $this->withToken($this->tokenFor($student))->post('/api/v1/student/speaking/exercises/'.$exercise->id.'/attempts', [
            'file' => UploadedFile::fake()->create('big.mp3', 2048, 'audio/mpeg'),
        ])->assertUnprocessable();
    }

    public function test_route_list_includes_student_and_teacher_speaking_endpoints(): void
    {
        $routes = collect(app('router')->getRoutes())->map(fn ($route) => $route->uri())->all();

        $this->assertContains('api/v1/student/speaking/exercises', $routes);
        $this->assertContains('api/v1/teacher/speaking/attempts', $routes);
    }

    private function classroomUsers(): array
    {
        $admin = User::factory()->admin()->create();
        $teacher = User::factory()->teacher()->approved()->create();
        $student = User::factory()->student()->approved()->create();
        $class = SchoolClass::factory()->create();
        TeacherClassAssignment::factory()->create(['teacher_id' => $teacher->id, 'class_id' => $class->id, 'assigned_by' => $admin->id, 'is_active' => true]);
        StudentClassMembership::factory()->create(['student_id' => $student->id, 'class_id' => $class->id, 'assigned_by' => $admin->id, 'is_active' => true]);

        return [$student, $teacher, $class];
    }

    private function exercise(SchoolClass $class, array $attributes = []): SpeakingExercise
    {
        return SpeakingExercise::query()->create([
            'title' => $attributes['title'] ?? 'Salam dasar',
            'target_text' => $attributes['target_text'] ?? 'Ari nggiro',
            'prompt_text' => 'Latihan demo',
            'classroom_id' => $class->id,
            'status' => $attributes['status'] ?? 'published',
        ]);
    }

    private function attemptFor(User $student, SpeakingExercise $exercise): SpeakingAttempt
    {
        $media = MediaFile::factory()->speakingRecording()->create(['uploaded_by' => $student->id]);

        return SpeakingAttempt::query()->create([
            'speaking_exercise_id' => $exercise->id,
            'student_id' => $student->id,
            'audio_media_id' => $media->id,
            'audio_path' => $media->path,
            'audio_disk' => $media->disk,
            'audio_mime_type' => $media->mime_type,
            'audio_size_bytes' => $media->size_bytes,
            'target_text_snapshot' => $exercise->target_text,
            'status' => 'completed',
        ]);
    }

    private function bindSpeakingAiSuccess(): void
    {
        $this->app->instance(SpeakingAiClient::class, new class extends SpeakingAiClient
        {
            public function enabled(): bool
            {
                return true;
            }

            public function analyze(SpeakingAttempt $attempt): array
            {
                return [
                    'engine' => 'fake',
                    'model' => 'fake-model',
                    'target' => $attempt->target_text_snapshot,
                    'transcription' => 'ari nggiro',
                    'score' => 82.5,
                    'alignment' => ['0_ari' => 100],
                    'warnings' => [],
                ];
            }
        });
    }

    private function bindSpeakingAiFailure(): void
    {
        $this->app->instance(SpeakingAiClient::class, new class extends SpeakingAiClient
        {
            public function enabled(): bool
            {
                return true;
            }

            public function analyze(SpeakingAttempt $attempt): array
            {
                throw new RuntimeException('AI unavailable');
            }
        });
    }

    private function tokenFor(User $user): string
    {
        return $user->createToken('PHPUnit')->plainTextToken;
    }
}
