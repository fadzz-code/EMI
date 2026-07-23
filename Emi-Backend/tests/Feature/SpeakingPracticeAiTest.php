<?php

namespace Tests\Feature;

use App\Exceptions\SpeakingAiException;
use App\Jobs\AnalyzeSpeakingAttemptJob;
use App\Models\MediaFile;
use App\Models\SchoolClass;
use App\Models\SpeakingAttempt;
use App\Models\SpeakingExercise;
use App\Models\StudentClassMembership;
use App\Models\TeacherClassAssignment;
use App\Models\User;
use App\Services\SpeakingAiClient;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
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
            ->assertJsonPath('data.ai_transcription', 'ari nggiro')
            ->assertJsonPath('data.ai_warnings.0', 'Perkiraan model');

        $attempt = SpeakingAttempt::query()->firstOrFail();
        $this->assertNotNull($attempt->audio_media_id);
        $this->assertNotNull($attempt->audio_path);
        $this->assertDatabaseMissing('speaking_attempts', ['audio_path' => 'binary']);
        Storage::disk($attempt->audio_disk)->assertExists($attempt->audio_path);
        $this->assertSame(['0_ari' => 100], $attempt->ai_alignment);
    }

    public function test_hardware_wav_persists_and_reaches_ai_before_polling_completed_result(): void
    {
        Storage::fake('local');
        config([
            'queue.default' => 'sync',
            'speaking.ai.enabled' => true,
            'speaking.ai.base_url' => 'https://speaking-ai.test',
            'speaking.ai.token' => 'service-secret',
        ]);
        $aiReceivedWav = false;
        Http::fake(function (Request $request) use (&$aiReceivedWav) {
            $aiReceivedWav = str_contains($request->body(), 'RIFF') && str_contains($request->body(), 'WAVE');

            return Http::response([
                'transcription' => 'ari nggiro',
                'score' => 91,
                'alignment' => [],
                'warnings' => ['Perkiraan model'],
            ]);
        });
        [$student, , $class] = $this->classroomUsers();
        $exercise = $this->exercise($class);
        $wav = $this->hardwareWav();

        $response = $this->withToken($this->tokenFor($student))->post('/api/v1/student/speaking/exercises/'.$exercise->id.'/attempts', [
            'file' => UploadedFile::fake()->createWithContent('speaking-emi.wav', $wav),
            'capture_source' => 'web_esp32_serial',
            'audio_duration_seconds' => 1,
        ])->assertCreated()->assertJsonPath('data.status', 'completed');

        $attempt = SpeakingAttempt::query()->with('audioMedia')->findOrFail($response->json('data.id'));
        $this->assertSame($attempt->audio_media_id, $attempt->audioMedia->id);
        $this->assertSame('local', $attempt->audioMedia->disk);
        $this->assertSame('audio/wav', $attempt->audioMedia->mime_type);
        $this->assertSame(strlen($wav), $attempt->audioMedia->size_bytes);
        Storage::disk('local')->assertExists($attempt->audioMedia->path);
        $this->assertSame($wav, Storage::disk('local')->get($attempt->audioMedia->path));
        $this->assertTrue($aiReceivedWav);
        $this->withToken($this->tokenFor($student))->getJson('/api/v1/student/speaking/attempts/'.$attempt->id)
            ->assertOk()
            ->assertJsonPath('data.status', 'completed')
            ->assertJsonPath('data.ai_score', 91)
            ->assertJsonPath('data.ai_transcription', 'ari nggiro');
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
            ->assertJsonPath('data.ai_error', 'Analisis speaking AI gagal.');
    }

    public function test_student_speaking_history_is_paginated_and_excludes_other_students(): void
    {
        [$student, , $class] = $this->classroomUsers();
        $exercise = $this->exercise($class);
        $ownAttempts = collect([
            $this->attemptFor($student, $exercise),
            $this->attemptFor($student, $exercise),
            $this->attemptFor($student, $exercise),
        ]);
        $other = User::factory()->student()->approved()->create();
        StudentClassMembership::factory()->create(['student_id' => $other->id, 'class_id' => $class->id, 'is_active' => true]);
        $otherAttempt = $this->attemptFor($other, $exercise);

        $response = $this->withToken($this->tokenFor($student))->getJson('/api/v1/student/speaking/attempts?per_page=2&page=2')
            ->assertOk()
            ->assertJsonPath('meta.current_page', 2)
            ->assertJsonPath('meta.last_page', 2)
            ->assertJsonPath('meta.total', 3)
            ->assertJsonCount(1, 'data')
            ->assertJsonMissing(['id' => $otherAttempt->id]);

        $this->assertTrue($ownAttempts->pluck('id')->contains($response->json('data.0.id')));
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
            ->assertJsonPath('data.review_status', 'reviewed')
            ->assertJsonPath('data.teacher_score', 85);

        $this->assertDatabaseHas('speaking_attempts', [
            'id' => $attempt->id,
            'reviewed_by_id' => $teacher->id,
            'review_status' => 'reviewed',
        ]);
    }

    public function test_teacher_cannot_access_unauthorized_attempt(): void
    {
        [$student, $teacher] = $this->classroomUsers();
        $otherClass = SchoolClass::factory()->create();
        $attempt = $this->attemptFor($student, $this->exercise($otherClass));

        $this->withToken($this->tokenFor($teacher))->getJson('/api/v1/teacher/speaking/attempts/'.$attempt->id)
            ->assertForbidden();
        $this->withToken($this->tokenFor($teacher))->patchJson('/api/v1/teacher/speaking/attempts/'.$attempt->id.'/feedback', [
            'teacher_score' => 80,
        ])->assertForbidden();
    }

    public function test_teacher_review_validates_score_range_and_allows_omitted_feedback(): void
    {
        [$student, $teacher, $class] = $this->classroomUsers();
        $attempt = $this->attemptFor($student, $this->exercise($class));
        $url = '/api/v1/teacher/speaking/attempts/'.$attempt->id.'/feedback';
        $token = $this->tokenFor($teacher);

        foreach ([-0.01, 100.01] as $score) {
            $this->withToken($token)->patchJson($url, ['teacher_score' => $score])
                ->assertUnprocessable()->assertJsonValidationErrors('teacher_score');
        }

        $this->withToken($token)->patchJson($url, ['teacher_score' => 100])
            ->assertOk()->assertJsonPath('data.review_status', 'reviewed')->assertJsonPath('data.teacher_feedback', null);
    }

    public function test_revoked_teacher_assignment_denies_exercise_attempt_review_and_recording_url(): void
    {
        [$student, $teacher, $class] = $this->classroomUsers();
        $exercise = $this->exercise($class);
        $attempt = $this->attemptFor($student, $exercise);
        $teacher->teacherClassAssignments()->update(['is_active' => false]);
        $token = $this->tokenFor($teacher);

        $this->withToken($token)->getJson('/api/v1/teacher/speaking/exercises/'.$exercise->id)->assertForbidden();
        $this->withToken($token)->getJson('/api/v1/teacher/speaking/attempts/'.$attempt->id)->assertForbidden();
        $this->withToken($token)->patchJson('/api/v1/teacher/speaking/attempts/'.$attempt->id.'/feedback', ['teacher_score' => 80])->assertForbidden();
        $this->withToken($token)->postJson('/api/v1/media/'.$attempt->audio_media_id.'/temporary-url')->assertForbidden();
    }

    public function test_assigned_teacher_can_request_private_recording_temporary_url(): void
    {
        Storage::fake('local');
        [$student, $teacher, $class] = $this->classroomUsers();
        $attempt = $this->attemptFor($student, $this->exercise($class));
        Storage::disk('local')->put($attempt->audioMedia->path, 'audio');

        $this->withToken($this->tokenFor($teacher))->postJson('/api/v1/media/'.$attempt->audio_media_id.'/temporary-url')
            ->assertOk()->assertJsonStructure(['data' => ['url', 'expires_at']]);
    }

    public function test_delayed_ai_job_does_not_overwrite_teacher_review(): void
    {
        config(['speaking.ai.enabled' => true]);
        [$student, $teacher, $class] = $this->classroomUsers();
        $attempt = $this->attemptFor($student, $this->exercise($class));
        $reviewedAt = now();
        $attempt->forceFill([
            'status' => 'reviewed',
            'teacher_score' => 88,
            'teacher_feedback' => 'Pertahankan tempo.',
            'reviewed_by_id' => $teacher->id,
            'reviewed_at' => $reviewedAt,
            'review_status' => 'reviewed',
        ])->save();
        $reviewedAt = $attempt->refresh()->reviewed_at;
        $client = new class extends SpeakingAiClient
        {
            public bool $called = false;

            public function enabled(): bool
            {
                return true;
            }

            public function analyze(SpeakingAttempt $attempt): array
            {
                $this->called = true;

                return ['transcription' => 'terlambat', 'score' => 1, 'alignment' => []];
            }
        };

        (new AnalyzeSpeakingAttemptJob($attempt->id))->handle($client);

        $attempt->refresh();
        $this->assertTrue($client->called);
        $this->assertSame('completed', $attempt->analysis_status);
        $this->assertSame('reviewed', $attempt->review_status);
        $this->assertSame(88.0, (float) $attempt->teacher_score);
        $this->assertSame('Pertahankan tempo.', $attempt->teacher_feedback);
        $this->assertSame($teacher->id, $attempt->reviewed_by_id);
        $this->assertTrue($reviewedAt->equalTo($attempt->reviewed_at));
    }

    public function test_teacher_can_manage_speaking_exercises_for_assigned_class(): void
    {
        [, $teacher, $class] = $this->classroomUsers();
        $existing = $this->exercise($class, ['title' => 'Target lama']);

        $this->withToken($this->tokenFor($teacher))->getJson('/api/v1/teacher/speaking/exercises')
            ->assertOk()
            ->assertJsonPath('data.0.id', $existing->id);

        $created = $this->withToken($this->tokenFor($teacher))->postJson('/api/v1/teacher/speaking/exercises', [
            'classroom_id' => $class->id,
            'title' => 'Salam baru',
            'target_text' => 'Ari nggiro lako',
            'prompt_text' => 'Baca dengan jelas.',
            'target_translation' => 'Selamat pagi semua',
            'difficulty' => 'mudah',
            'status' => 'published',
        ])->assertCreated()
            ->assertJsonPath('data.classroom_id', $class->id)
            ->assertJsonPath('data.created_by_id', $teacher->id)
            ->assertJsonPath('data.title', 'Salam baru')
            ->json('data');

        $this->withToken($this->tokenFor($teacher))->patchJson('/api/v1/teacher/speaking/exercises/'.$created['id'], [
            'title' => 'Salam diperbarui',
            'target_text' => 'Ari nggiro lako EMI',
        ])->assertOk()
            ->assertJsonPath('data.title', 'Salam diperbarui');

        $this->withToken($this->tokenFor($teacher))->patchJson('/api/v1/teacher/speaking/exercises/'.$created['id'].'/archive')
            ->assertOk()
            ->assertJsonPath('data.status', 'archived');
    }

    public function test_teacher_can_delete_own_speaking_exercise(): void
    {
        [$student, $teacher, $class] = $this->classroomUsers();
        $exercise = $this->exercise($class);
        $exercise->forceFill(['created_by_id' => $teacher->id])->save();

        $this->withToken($this->tokenFor($teacher))->deleteJson('/api/v1/teacher/speaking/exercises/'.$exercise->id)
            ->assertOk()
            ->assertJsonPath('message', 'Latihan speaking berhasil dihapus.');

        $this->assertSoftDeleted($exercise);
        $this->withToken($this->tokenFor($teacher))->getJson('/api/v1/teacher/speaking/exercises')->assertJsonMissing(['id' => $exercise->id]);
        $this->withToken($this->tokenFor($student))->getJson('/api/v1/student/speaking/exercises')->assertJsonMissing(['id' => $exercise->id]);
    }

    public function test_teacher_cannot_delete_other_teacher_unassigned_or_global_exercise(): void
    {
        [, $teacher, $class] = $this->classroomUsers();
        $otherTeacher = User::factory()->teacher()->approved()->create();
        $other = $this->exercise($class);
        $other->forceFill(['created_by_id' => $otherTeacher->id])->save();
        $unassigned = $this->exercise(SchoolClass::factory()->create());

        foreach ([$other, $unassigned, $this->globalExercise()] as $exercise) {
            $this->withToken($this->tokenFor($teacher))->deleteJson('/api/v1/teacher/speaking/exercises/'.$exercise->id)->assertForbidden();
            $this->assertDatabaseHas('speaking_exercises', ['id' => $exercise->id, 'deleted_at' => null]);
        }
    }

    public function test_inactive_assignment_class_or_school_denies_teacher_exercise_deletion(): void
    {
        foreach (['assignment', 'class', 'school'] as $inactive) {
            [, $teacher, $class] = $this->classroomUsers();
            $exercise = $this->exercise($class);
            $exercise->forceFill(['created_by_id' => $teacher->id])->save();

            match ($inactive) {
                'assignment' => $teacher->teacherClassAssignments()->update(['is_active' => false]),
                'class' => $class->update(['status' => 'inactive']),
                'school' => $class->school()->update(['status' => 'inactive']),
            };

            $this->withToken($this->tokenFor($teacher))->deleteJson('/api/v1/teacher/speaking/exercises/'.$exercise->id)->assertForbidden();
            $this->assertDatabaseHas('speaking_exercises', ['id' => $exercise->id, 'deleted_at' => null]);
        }
    }

    public function test_student_and_guest_cannot_delete_teacher_speaking_exercise(): void
    {
        [$student, $teacher, $class] = $this->classroomUsers();
        $exercise = $this->exercise($class);
        $exercise->forceFill(['created_by_id' => $teacher->id])->save();
        $url = '/api/v1/teacher/speaking/exercises/'.$exercise->id;

        $this->deleteJson($url)->assertUnauthorized();
        $this->withToken($this->tokenFor($student))->deleteJson($url)->assertForbidden();
        $this->assertDatabaseHas('speaking_exercises', ['id' => $exercise->id, 'deleted_at' => null]);
    }

    public function test_deleting_exercise_preserves_shared_reference_media(): void
    {
        [, $teacher, $class] = $this->classroomUsers();
        $media = MediaFile::factory()->audio()->create(['purpose' => 'speaking_reference_audio']);
        $exercise = $this->exercise($class);
        $exercise->forceFill(['created_by_id' => $teacher->id, 'reference_audio_media_id' => $media->id])->save();
        $this->globalExercise(['reference_audio_media_id' => $media->id]);

        $this->withToken($this->tokenFor($teacher))->deleteJson('/api/v1/teacher/speaking/exercises/'.$exercise->id)->assertOk();

        $this->assertDatabaseHas('media_files', ['id' => $media->id, 'deleted_at' => null]);
    }

    public function test_exercise_with_attempt_cannot_be_deleted_and_all_results_are_preserved(): void
    {
        [$student, $teacher, $class] = $this->classroomUsers();
        $exercise = $this->exercise($class);
        $exercise->forceFill(['created_by_id' => $teacher->id])->save();
        $attempt = $this->attemptFor($student, $exercise);
        $attempt->forceFill(['ai_score' => 91, 'teacher_score' => 88, 'teacher_feedback' => 'Pertahankan tempo.'])->save();
        $media = $attempt->audioMedia;

        $this->withToken($this->tokenFor($teacher))->deleteJson('/api/v1/teacher/speaking/exercises/'.$exercise->id)
            ->assertUnprocessable()
            ->assertJsonPath('message', 'Latihan yang sudah memiliki hasil siswa tidak dapat dihapus. Arsipkan latihan ini agar tidak lagi tampil kepada siswa.');

        $this->assertDatabaseHas('speaking_exercises', ['id' => $exercise->id, 'deleted_at' => null]);
        $this->assertDatabaseHas('speaking_attempts', ['id' => $attempt->id, 'audio_media_id' => $media->id, 'ai_score' => 91, 'teacher_score' => 88, 'teacher_feedback' => 'Pertahankan tempo.', 'deleted_at' => null]);
        $this->assertDatabaseHas('media_files', ['id' => $media->id, 'deleted_at' => null]);
    }

    public function test_teacher_cannot_manage_speaking_exercises_for_unassigned_class(): void
    {
        [, $teacher] = $this->classroomUsers();
        $otherClass = SchoolClass::factory()->create();
        $otherExercise = $this->exercise($otherClass);

        $this->withToken($this->tokenFor($teacher))->postJson('/api/v1/teacher/speaking/exercises', [
            'classroom_id' => $otherClass->id,
            'title' => 'Tidak boleh',
            'target_text' => 'Target lain',
            'status' => 'published',
        ])->assertUnprocessable();

        $this->withToken($this->tokenFor($teacher))->patchJson('/api/v1/teacher/speaking/exercises/'.$otherExercise->id, [
            'title' => 'Tidak boleh update',
        ])->assertForbidden();
    }

    public function test_student_sees_published_class_exercise_but_not_archived_exercise(): void
    {
        [$student, , $class] = $this->classroomUsers();
        $published = $this->exercise($class, ['title' => 'Published target']);
        $this->exercise($class, ['title' => 'Archived target', 'status' => 'archived']);

        $this->withToken($this->tokenFor($student))->getJson('/api/v1/student/speaking/exercises')
            ->assertOk()
            ->assertJsonPath('data.0.id', $published->id)
            ->assertJsonCount(1, 'data');
    }

    public function test_admin_can_manage_global_speaking_exercises_with_reference_audio(): void
    {
        [$student, $teacher, $class] = $this->classroomUsers();
        $admin = User::query()->where('role', 'admin')->firstOrFail();
        $media = MediaFile::factory()->create([
            'uploaded_by' => $admin->id,
            'purpose' => 'speaking_reference_audio',
            'mime_type' => 'audio/mpeg',
            'visibility' => 'public',
        ]);

        $created = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/speaking/exercises', [
            'title' => 'Global Target',
            'target_text' => 'Baca ini',
            'reference_audio_media_id' => $media->id,
            'status' => 'published',
        ])->assertCreated()
            ->assertJsonPath('data.classroom_id', null)
            ->assertJsonPath('data.reference_audio_media_id', $media->id)
            ->assertJsonPath('data.reference_audio.id', $media->id)
            ->json('data');

        $this->withToken($this->tokenFor($admin))->getJson('/api/v1/admin/speaking/exercises')
            ->assertOk()
            ->assertJsonPath('data.0.id', $created['id']);

        $this->withToken($this->tokenFor($admin))->patchJson('/api/v1/admin/speaking/exercises/'.$created['id'], [
            'title' => 'Global Target Updated',
        ])->assertOk()
            ->assertJsonPath('data.title', 'Global Target Updated');

        $this->withToken($this->tokenFor($admin))->patchJson('/api/v1/admin/speaking/exercises/'.$created['id'].'/archive')
            ->assertOk()
            ->assertJsonPath('data.status', 'archived');
    }

    public function test_admin_can_list_and_view_only_global_speaking_exercises(): void
    {
        $admin = User::factory()->admin()->create();
        $global = $this->globalExercise();
        $classExercise = $this->exercise(SchoolClass::factory()->create());

        $this->withToken($this->tokenFor($admin))->getJson('/api/v1/admin/speaking/exercises')
            ->assertOk()
            ->assertJsonFragment(['id' => $global->id])
            ->assertJsonMissing(['id' => $classExercise->id]);

        $this->withToken($this->tokenFor($admin))->getJson('/api/v1/admin/speaking/exercises/'.$global->id)
            ->assertOk()
            ->assertJsonPath('data.id', $global->id);

        $this->withToken($this->tokenFor($admin))->getJson('/api/v1/admin/speaking/exercises/'.$classExercise->id)
            ->assertForbidden();
    }

    public function test_admin_list_supports_search_status_and_validated_pagination(): void
    {
        $admin = User::factory()->admin()->create();
        $title = $this->globalExercise(['title' => 'Nanas unik', 'status' => 'draft']);
        $target = $this->globalExercise(['target_text' => 'Nanas target', 'status' => 'draft']);
        $prompt = $this->globalExercise(['prompt_text' => 'Nanas prompt', 'status' => 'draft']);
        $this->globalExercise(['title' => 'Nanas terbit', 'status' => 'published']);

        $response = $this->withToken($this->tokenFor($admin))->getJson('/api/v1/admin/speaking/exercises?search=Nanas&status=draft&per_page=2&page=2')
            ->assertOk()
            ->assertJsonPath('meta.per_page', 2)
            ->assertJsonPath('meta.current_page', 2);

        $this->assertEqualsCanonicalizing([$title->id, $target->id, $prompt->id], collect($response->json('data'))->pluck('id')->merge(
            $this->withToken($this->tokenFor($admin))->getJson('/api/v1/admin/speaking/exercises?search=Nanas&status=draft&per_page=2&page=1')->json('data.*.id')
        )->all());

        $this->withToken($this->tokenFor($admin))->getJson('/api/v1/admin/speaking/exercises?status=bad&per_page=101')
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['status', 'per_page']);
    }

    public function test_admin_creates_global_draft_with_server_owned_fields(): void
    {
        $admin = User::factory()->admin()->create();
        $other = User::factory()->admin()->create();
        $class = SchoolClass::factory()->create();

        $created = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/speaking/exercises', [
            'title' => 'Draft global',
            'target_text' => 'Target draft',
            'classroom_id' => $class->id,
            'created_by_id' => $other->id,
        ])->assertCreated()
            ->assertJsonPath('data.status', 'draft')
            ->assertJsonPath('data.classroom_id', null)
            ->assertJsonPath('data.created_by_id', $admin->id)
            ->json('data');

        $this->assertDatabaseHas('speaking_exercises', ['id' => $created['id'], 'classroom_id' => null, 'created_by_id' => $admin->id]);
    }

    public function test_admin_updates_and_publishes_ready_global_exercise(): void
    {
        $admin = User::factory()->admin()->create();
        $exercise = $this->globalExercise(['status' => 'draft']);

        $this->withToken($this->tokenFor($admin))->patchJson('/api/v1/admin/speaking/exercises/'.$exercise->id, [
            'title' => 'Siap terbit',
            'target_text' => 'Target siap',
            'status' => 'published',
        ])->assertOk()
            ->assertJsonPath('data.title', 'Siap terbit')
            ->assertJsonPath('data.status', 'published');
    }

    public function test_admin_cannot_publish_unready_global_exercise(): void
    {
        $admin = User::factory()->admin()->create();
        $exercise = $this->globalExercise(['status' => 'draft']);
        $exercise->forceFill(['title' => '', 'target_text' => ''])->save();

        $this->withToken($this->tokenFor($admin))->patchJson('/api/v1/admin/speaking/exercises/'.$exercise->id, ['status' => 'published'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['title', 'target_text']);
    }

    public function test_admin_archives_without_deleting_global_exercise(): void
    {
        $admin = User::factory()->admin()->create();
        $exercise = $this->globalExercise();

        $this->withToken($this->tokenFor($admin))->patchJson('/api/v1/admin/speaking/exercises/'.$exercise->id.'/archive')
            ->assertOk()
            ->assertJsonPath('data.status', 'archived');

        $this->assertDatabaseHas('speaking_exercises', ['id' => $exercise->id, 'status' => 'archived', 'deleted_at' => null]);
    }

    public function test_admin_accepts_only_active_speaking_reference_audio(): void
    {
        $admin = User::factory()->admin()->create();
        $valid = MediaFile::factory()->audio()->create(['purpose' => 'speaking_reference_audio']);

        $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/speaking/exercises', [
            'title' => 'Dengan audio',
            'target_text' => 'Target audio',
            'reference_audio_media_id' => $valid->id,
        ])->assertCreated()->assertJsonPath('data.reference_audio_media_id', $valid->id);

        $wrongPurpose = MediaFile::factory()->audio()->create();
        $wrongMime = MediaFile::factory()->create(['purpose' => 'speaking_reference_audio', 'mime_type' => 'application/pdf']);
        $deleted = MediaFile::factory()->audio()->create(['purpose' => 'speaking_reference_audio']);
        $deleted->delete();

        foreach ([$wrongPurpose, $wrongMime, $deleted] as $media) {
            $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/speaking/exercises', [
                'title' => 'Audio invalid',
                'target_text' => 'Target',
                'reference_audio_media_id' => $media->id,
            ])->assertUnprocessable()->assertJsonValidationErrors('reference_audio_media_id');
        }
    }

    public function test_admin_update_without_audio_retains_existing_audio(): void
    {
        $admin = User::factory()->admin()->create();
        $media = MediaFile::factory()->audio()->create(['purpose' => 'speaking_reference_audio']);
        $exercise = $this->globalExercise(['reference_audio_media_id' => $media->id]);

        $this->withToken($this->tokenFor($admin))->patchJson('/api/v1/admin/speaking/exercises/'.$exercise->id, ['title' => 'Audio tetap'])
            ->assertOk()
            ->assertJsonPath('data.reference_audio_media_id', $media->id);

        $this->assertDatabaseHas('speaking_exercises', ['id' => $exercise->id, 'reference_audio_media_id' => $media->id]);
    }

    public function test_non_admins_and_guest_cannot_access_admin_speaking_api(): void
    {
        $exercise = $this->globalExercise();

        $this->getJson('/api/v1/admin/speaking/exercises')->assertUnauthorized();

        foreach ([User::factory()->teacher()->approved()->create(), User::factory()->student()->approved()->create()] as $user) {
            $this->withToken($this->tokenFor($user))->getJson('/api/v1/admin/speaking/exercises')->assertForbidden();
            $this->withToken($this->tokenFor($user))->patchJson('/api/v1/admin/speaking/exercises/'.$exercise->id, ['title' => 'Ditolak'])->assertForbidden();
        }
    }

    public function test_admin_speaking_has_no_hard_delete_route(): void
    {
        $admin = User::factory()->admin()->create();
        $exercise = $this->globalExercise();

        $this->withToken($this->tokenFor($admin))->deleteJson('/api/v1/admin/speaking/exercises/'.$exercise->id)->assertMethodNotAllowed();
        $this->assertDatabaseHas('speaking_exercises', ['id' => $exercise->id, 'deleted_at' => null]);
    }

    public function test_admin_speaking_response_does_not_expose_storage_fields(): void
    {
        $admin = User::factory()->admin()->create();
        $media = MediaFile::factory()->audio()->create(['purpose' => 'speaking_reference_audio', 'path' => 'private/secret/audio.mp3']);
        $exercise = $this->globalExercise(['reference_audio_media_id' => $media->id]);

        $content = $this->withToken($this->tokenFor($admin))->getJson('/api/v1/admin/speaking/exercises/'.$exercise->id)
            ->assertOk()
            ->assertJsonMissingPath('data.reference_audio.path')
            ->assertJsonMissingPath('data.reference_audio.disk')
            ->content();

        $this->assertStringNotContainsString('private/secret/audio.mp3', $content);
    }

    public function test_teacher_can_list_published_global_speaking_templates_only(): void
    {
        [, $teacher] = $this->classroomUsers();
        $published = $this->globalExercise(['title' => 'Template terbit']);
        $this->globalExercise(['title' => 'Template draft', 'status' => 'draft']);
        $this->globalExercise(['title' => 'Template arsip', 'status' => 'archived']);

        $this->withToken($this->tokenFor($teacher))->getJson('/api/v1/teacher/speaking/templates')
            ->assertOk()
            ->assertJsonPath('data.0.id', $published->id)
            ->assertJsonCount(1, 'data');
    }

    public function test_teacher_can_create_class_exercise_from_template_with_overrides_and_reference_audio(): void
    {
        [, $teacher, $class] = $this->classroomUsers();
        $admin = User::factory()->admin()->create();
        $media = MediaFile::factory()->create([
            'uploaded_by' => $admin->id,
            'purpose' => 'speaking_reference_audio',
            'visibility' => 'public',
        ]);
        $template = $this->globalExercise([
            'title' => 'Judul template',
            'target_text' => 'Teks template',
            'target_translation' => 'Terjemahan template',
            'prompt_text' => 'Prompt template',
            'difficulty' => 'sedang',
            'reference_audio_media_id' => $media->id,
        ]);

        $created = $this->withToken($this->tokenFor($teacher))->postJson('/api/v1/teacher/speaking/exercises', [
            'template_exercise_id' => $template->id,
            'classroom_id' => $class->id,
            'title' => 'Judul override',
            'prompt_text' => 'Prompt override',
            'difficulty' => 'mudah',
            'status' => 'published',
        ])->assertCreated()
            ->assertJsonPath('data.classroom_id', $class->id)
            ->assertJsonPath('data.created_by_id', $teacher->id)
            ->assertJsonPath('data.title', 'Judul override')
            ->assertJsonPath('data.target_text', 'Teks template')
            ->assertJsonPath('data.target_translation', 'Terjemahan template')
            ->assertJsonPath('data.prompt_text', 'Prompt override')
            ->assertJsonPath('data.difficulty', 'mudah')
            ->assertJsonPath('data.status', 'published')
            ->assertJsonPath('data.reference_audio_media_id', $media->id)
            ->json('data');

        $this->assertDatabaseHas('speaking_exercises', [
            'id' => $created['id'],
            'classroom_id' => $class->id,
            'created_by_id' => $teacher->id,
            'reference_audio_media_id' => $media->id,
        ]);
    }

    public function test_teacher_cannot_use_draft_template_or_unassigned_class(): void
    {
        [, $teacher] = $this->classroomUsers();
        $otherClass = SchoolClass::factory()->create();
        $draft = $this->globalExercise(['status' => 'draft']);

        $this->withToken($this->tokenFor($teacher))->postJson('/api/v1/teacher/speaking/exercises', [
            'template_exercise_id' => $draft->id,
            'classroom_id' => $otherClass->id,
        ])->assertUnprocessable();

        $published = $this->globalExercise();

        $this->withToken($this->tokenFor($teacher))->postJson('/api/v1/teacher/speaking/exercises', [
            'template_exercise_id' => $published->id,
            'classroom_id' => $otherClass->id,
        ])->assertUnprocessable();
    }

    public function test_student_sees_template_created_class_exercise_with_reference_audio(): void
    {
        [$student, $teacher, $class] = $this->classroomUsers();
        $admin = User::factory()->admin()->create();
        $media = MediaFile::factory()->create([
            'uploaded_by' => $admin->id,
            'purpose' => 'speaking_reference_audio',
            'visibility' => 'public',
        ]);
        $template = $this->globalExercise(['reference_audio_media_id' => $media->id]);

        $created = $this->withToken($this->tokenFor($teacher))->postJson('/api/v1/teacher/speaking/exercises', [
            'template_exercise_id' => $template->id,
            'classroom_id' => $class->id,
            'status' => 'published',
        ])->assertCreated()->json('data');

        Sanctum::actingAs($student);

        $this->getJson('/api/v1/student/speaking/exercises')
            ->assertOk()
            ->assertJsonFragment(['id' => $created['id']])
            ->assertJsonFragment(['reference_audio_media_id' => $media->id]);
    }

    public function test_student_resource_includes_reference_audio(): void
    {
        [$student, , $class] = $this->classroomUsers();
        $admin = User::factory()->admin()->create();
        $media = MediaFile::factory()->create([
            'uploaded_by' => $admin->id,
            'purpose' => 'speaking_reference_audio',
            'visibility' => 'public',
        ]);

        $published = $this->exercise($class, ['title' => 'With audio']);
        $published->forceFill(['reference_audio_media_id' => $media->id])->save();

        $this->withToken($this->tokenFor($student))->getJson('/api/v1/student/speaking/exercises')
            ->assertOk()
            ->assertJsonPath('data.0.id', $published->id)
            ->assertJsonPath('data.0.reference_audio.id', $media->id);
    }

    public function test_capture_source_defaults_and_accepts_every_supported_value(): void
    {
        Storage::fake('local');
        config(['speaking.ai.enabled' => false]);
        [$student, , $class] = $this->classroomUsers();
        $exercise = $this->exercise($class);
        $url = '/api/v1/student/speaking/exercises/'.$exercise->id.'/attempts';

        $this->withToken($this->tokenFor($student))->post($url, [
            'file' => UploadedFile::fake()->create('default.webm', 10, 'audio/webm'),
        ])->assertCreated()->assertJsonPath('data.capture_source', 'web_microphone');

        foreach (['web_microphone', 'web_esp32_serial', 'mobile_microphone', 'mobile_esp32_bluetooth'] as $source) {
            $this->withToken($this->tokenFor($student))->post($url, [
                'file' => UploadedFile::fake()->create($source.'.webm', 10, 'audio/webm'),
                'capture_source' => $source,
            ])->assertCreated()->assertJsonPath('data.capture_source', $source);
            $this->assertDatabaseHas('speaking_attempts', ['capture_source' => $source]);
        }
    }

    public function test_attempt_submission_rejects_invalid_source_guest_nonstudent_and_out_of_class_student(): void
    {
        Storage::fake('local');
        [$student, $teacher, $class] = $this->classroomUsers();
        $exercise = $this->exercise($class);
        $url = '/api/v1/student/speaking/exercises/'.$exercise->id.'/attempts';
        $payload = ['file' => UploadedFile::fake()->create('recording.webm', 10, 'audio/webm')];

        $this->postJson($url, $payload)->assertUnauthorized();
        $this->withToken($this->tokenFor($teacher))->post($url, $payload)->assertForbidden();
        $outsider = User::factory()->student()->approved()->create();
        $this->withToken($this->tokenFor($outsider))->post($url, $payload)->assertForbidden();
        Sanctum::actingAs($student);
        $this->post($url, $payload + ['capture_source' => 'unknown'])->assertUnprocessable()->assertJsonValidationErrors('capture_source');
    }

    public function test_ai_client_sends_bearer_token_and_accepts_valid_response(): void
    {
        Storage::fake('local');
        config([
            'speaking.ai.enabled' => true,
            'speaking.ai.base_url' => 'https://speaking-ai.test',
            'speaking.ai.token' => 'service-secret',
            'speaking.ai.connect_timeout_seconds' => 2,
            'speaking.ai.timeout_seconds' => 9,
        ]);
        [$student, , $class] = $this->classroomUsers();
        $attempt = $this->attemptFor($student, $this->exercise($class));
        Storage::disk('local')->put($attempt->audioMedia->path, 'webm');
        Http::fake(['speaking-ai.test/*' => Http::response(['transcription' => 'ari', 'score' => 90, 'alignment' => []])]);

        app(SpeakingAiClient::class)->analyze($attempt->load('audioMedia'));

        Http::assertSent(fn (Request $request): bool => $request->hasHeader('Authorization', 'Bearer service-secret'));
    }

    public function test_ai_client_maps_upstream_error_codes(): void
    {
        Storage::fake('local');
        config(['speaking.ai.enabled' => true, 'speaking.ai.base_url' => 'https://speaking-ai.test']);
        [$student, , $class] = $this->classroomUsers();
        $attempt = $this->attemptFor($student, $this->exercise($class));
        Storage::disk('local')->put($attempt->audioMedia->path, 'wav');

        Http::fake(['speaking-ai.test/*' => Http::sequence()
            ->push(['code' => 'SPEAKING_AI_UNAUTHORIZED', 'error' => 'private'], 401)
            ->push(['code' => 'SPEAKING_AI_VALIDATION_ERROR', 'error' => 'private'], 422)
            ->push(['code' => 'SPEAKING_AI_TIMEOUT', 'error' => 'private'], 503)
            ->push(['code' => 'SPEAKING_AI_TIMEOUT', 'error' => 'private'], 503)
            ->push(['code' => 'SPEAKING_AI_UNAVAILABLE', 'error' => 'private'], 503)
            ->push(['code' => 'SPEAKING_AI_UNAVAILABLE', 'error' => 'private'], 503)]);

        foreach ([
            'SPEAKING_AI_UNAUTHORIZED',
            'SPEAKING_AI_INVALID_AUDIO',
            'SPEAKING_AI_TIMEOUT',
            'SPEAKING_AI_UNAVAILABLE',
        ] as $expectedCode) {
            try {
                app(SpeakingAiClient::class)->analyze($attempt->load('audioMedia'));
                $this->fail('Expected AI failure.');
            } catch (SpeakingAiException $exception) {
                $this->assertSame($expectedCode, $exception->errorCode);
            }
        }
    }

    public function test_ai_client_rejects_missing_file_and_invalid_response_with_specific_codes(): void
    {
        Storage::fake('local');
        config(['speaking.ai.enabled' => true, 'speaking.ai.base_url' => 'https://speaking-ai.test']);
        [$student, , $class] = $this->classroomUsers();
        $attempt = $this->attemptFor($student, $this->exercise($class));

        try {
            app(SpeakingAiClient::class)->analyze($attempt->load('audioMedia'));
            $this->fail('Expected missing file failure.');
        } catch (SpeakingAiException $exception) {
            $this->assertSame('SPEAKING_AUDIO_FILE_MISSING', $exception->errorCode);
        }

        Storage::disk('local')->put($attempt->audioMedia->path, 'wav');
        Http::fake(['speaking-ai.test/*' => Http::response(['score' => 90], 200)]);
        try {
            app(SpeakingAiClient::class)->analyze($attempt->load('audioMedia'));
            $this->fail('Expected invalid response failure.');
        } catch (SpeakingAiException $exception) {
            $this->assertSame('SPEAKING_AI_RESPONSE_INVALID', $exception->errorCode);
        }
    }

    public function test_ai_client_retries_server_errors_and_returns_stable_error(): void
    {
        Storage::fake('local');
        config(['speaking.ai.enabled' => true, 'speaking.ai.base_url' => 'https://speaking-ai.test']);
        [$student, , $class] = $this->classroomUsers();
        $attempt = $this->attemptFor($student, $this->exercise($class));
        Storage::disk('local')->put($attempt->audioMedia->path, 'webm');
        Http::fake(['speaking-ai.test/*' => Http::response(['secret' => 'upstream leak'], 500)]);

        try {
            app(SpeakingAiClient::class)->analyze($attempt->load('audioMedia'));
            $this->fail('Expected AI failure.');
        } catch (RuntimeException $exception) {
            $this->assertSame('Analisis speaking AI gagal.', $exception->getMessage());
        }

        Http::assertSentCount(2);
    }

    public function test_speaking_contract_keeps_recording_private_without_public_routes_or_global_converter(): void
    {
        Storage::fake('local');
        config(['speaking.ai.enabled' => false]);
        [$student, , $class] = $this->classroomUsers();
        $exercise = $this->exercise($class);

        $response = $this->withToken($this->tokenFor($student))->post('/api/v1/student/speaking/exercises/'.$exercise->id.'/attempts', [
            'file' => UploadedFile::fake()->create('recording.webm', 10, 'audio/webm'),
        ])->assertCreated()->assertJsonPath('data.audio_url', fn (string $url): bool => str_starts_with($url, '/api/v1/media/'));

        $attempt = SpeakingAttempt::query()->findOrFail($response->json('data.id'));
        $this->assertSame('private', $attempt->audioMedia->visibility);
        $this->assertSame('webm', $attempt->audioMedia->extension);
        $modelSource = file_get_contents(app_path('Models/MediaFile.php'));
        $this->assertStringNotContainsString('convert', strtolower($modelSource));
        $this->assertStringNotContainsString('ffmpeg', strtolower($modelSource));
        $routes = collect(app('router')->getRoutes())->map(fn ($route) => $route->uri());
        $this->assertFalse($routes->contains(fn (string $uri): bool => str_contains($uri, 'audio-list')));
        $this->assertFalse($routes->contains(fn (string $uri): bool => str_contains($uri, 'public/speaking')));
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
        $routes = collect(app('router')->getRoutes());
        $uris = $routes->map(fn ($route) => $route->uri())->all();

        $this->assertContains('api/v1/student/speaking/exercises', $uris);
        $this->assertContains('api/v1/teacher/speaking/templates', $uris);
        $this->assertContains('api/v1/teacher/speaking/exercises', $uris);
        $this->assertContains('api/v1/teacher/speaking/exercises/{exercise}/archive', $uris);
        $this->assertContains('api/v1/teacher/speaking/attempts', $uris);
        $this->assertTrue($routes->contains(fn ($route): bool => $route->uri() === 'api/v1/teacher/speaking/exercises/{exercise}' && in_array('DELETE', $route->methods(), true)));
    }

    private function classroomUsers(): array
    {
        $admin = User::query()->where('role', 'admin')->first() ?? User::factory()->admin()->create();
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

    private function globalExercise(array $attributes = []): SpeakingExercise
    {
        return SpeakingExercise::query()->create([
            'title' => $attributes['title'] ?? 'Template speaking',
            'target_text' => $attributes['target_text'] ?? 'Ari nggiro',
            'target_translation' => $attributes['target_translation'] ?? null,
            'prompt_text' => $attributes['prompt_text'] ?? 'Latihan template',
            'difficulty' => $attributes['difficulty'] ?? 'mudah',
            'reference_audio_media_id' => $attributes['reference_audio_media_id'] ?? null,
            'classroom_id' => null,
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
                    'warnings' => ['Perkiraan model', 123],
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

    private function hardwareWav(): string
    {
        $pcm = str_repeat("\0", 32_000);

        return 'RIFF'.pack('V', 36 + strlen($pcm)).'WAVEfmt '.pack('VvvVVvv', 16, 1, 1, 16_000, 32_000, 2, 16).'data'.pack('V', strlen($pcm)).$pcm;
    }

    private function tokenFor(User $user): string
    {
        return $user->createToken('PHPUnit')->plainTextToken;
    }
}
