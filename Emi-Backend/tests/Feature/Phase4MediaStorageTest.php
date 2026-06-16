<?php

namespace Tests\Feature;

use App\Exceptions\ApiException;
use App\Models\AuditLog;
use App\Models\MediaFile;
use App\Models\User;
use App\Services\AuditLogService;
use App\Services\MediaUploadService;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Storage;
use RuntimeException;
use Tests\TestCase;

class Phase4MediaStorageTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('public');
        Storage::fake('local');
        config([
            'media.public_disk' => 'public',
            'media.private_disk' => 'local',
            'media.signed_url_ttl_minutes' => 15,
            'media.max_kb.image' => 5120,
            'media.max_kb.document' => 25600,
            'media.max_kb.audio' => 30720,
        ]);
    }

    public function test_media_schema_model_relationships_and_constraints(): void
    {
        $uploader = User::factory()->admin()->create();
        $media = MediaFile::factory()->public()->create(['uploaded_by' => $uploader->id]);
        $uploader->forceFill(['avatar_media_id' => $media->id])->save();

        $this->assertIsString($media->id);
        $this->assertSame($uploader->id, $media->uploader->id);
        $this->assertSame($media->id, $uploader->refresh()->avatarMedia->id);
        $media->delete();
        $this->assertSoftDeleted('media_files', ['id' => $media->id]);

        $this->expectException(QueryException::class);
        MediaFile::factory()->create(['purpose' => 'video', 'visibility' => 'public']);
    }

    public function test_visibility_invalid_is_rejected_by_database(): void
    {
        $this->expectException(QueryException::class);

        MediaFile::factory()->create(['visibility' => 'internal']);
    }

    public function test_upload_requires_auth_and_role_purpose_visibility_rules_are_enforced(): void
    {
        $this->withHeaders(['Accept' => 'application/json'])->post('/api/v1/media', [
            'file' => $this->pdfFile(),
            'purpose' => 'document',
            'visibility' => 'private',
        ])->assertUnauthorized();

        $admin = User::factory()->admin()->create();
        foreach (['avatar', 'question_image', 'document', 'audio', 'speaking_recording'] as $purpose) {
            $this->uploadMedia($admin, $purpose, $this->fileForPurpose($purpose), 'private')
                ->assertCreated();
        }

        $teacher = User::factory()->teacher()->approved()->create();
        $this->uploadMedia($teacher, 'question_image', $this->pngFile(), 'public')->assertCreated();
        $this->uploadMedia($teacher, 'document', $this->pdfFile(), 'private')->assertCreated();
        $this->uploadMedia($teacher, 'audio', $this->mp3File(), 'private')->assertCreated();
        $this->uploadMedia($teacher, 'speaking_recording', $this->mp3File(), 'private')->assertForbidden();

        $student = User::factory()->student()->approved()->create();
        $this->uploadMedia($student, 'avatar', $this->pngFile(), 'private')
            ->assertCreated()
            ->assertJsonPath('data.visibility', 'public');
        $this->uploadMedia($student, 'speaking_recording', $this->mp3File(), 'public')
            ->assertCreated()
            ->assertJsonPath('data.visibility', 'private')
            ->assertJsonPath('data.url', null);
        $this->uploadMedia($student, 'document', $this->pdfFile(), 'private')->assertForbidden();
        $this->uploadMedia($student, 'question_image', $this->pngFile(), 'public')->assertForbidden();
    }

    public function test_upload_metadata_storage_checksum_mime_size_and_rejected_client_controlled_fields(): void
    {
        $teacher = User::factory()->teacher()->approved()->create();
        $file = $this->pdfFile('materi berbahaya..pdf');

        $response = $this->uploadMedia($teacher, 'document', $file, 'private', [
            'disk' => 's3',
        ])->assertUnprocessable()->assertJsonPath('code', 'VALIDATION_ERROR');
        $this->assertArrayHasKey('disk', $response->json('errors'));

        $response = $this->uploadMedia($teacher, 'document', $file, 'private')->assertCreated();
        $media = MediaFile::query()->findOrFail($response->json('data.id'));

        Storage::disk('local')->assertExists($media->path);
        $this->assertSame('local', $media->disk);
        $this->assertStringStartsWith('media/document/'.now()->format('Y/m')."/{$teacher->id}/", $media->path);
        $this->assertStringNotContainsString($media->original_name, $media->path);
        $this->assertNotSame($media->original_name, $media->stored_name);
        $this->assertSame(hash('sha256', $this->pdfContent()), $media->checksum_sha256);
        $this->assertSame(strlen($this->pdfContent()), $media->size_bytes);
        $this->assertSame('application/pdf', $media->mime_type);

        $response->assertJsonMissingPath('data.disk')
            ->assertJsonMissingPath('data.path')
            ->assertJsonMissingPath('data.checksum_sha256');
        $this->assertDatabaseHas('audit_logs', ['action' => 'media.uploaded']);
    }

    public function test_upload_validation_rejects_large_wrong_mime_svg_and_script_files(): void
    {
        $admin = User::factory()->admin()->create();
        config(['media.max_kb.document' => 0]);

        $this->uploadMedia($admin, 'document', $this->pdfFile(), 'private')
            ->assertUnprocessable()
            ->assertJsonPath('code', 'MEDIA_FILE_TOO_LARGE');

        config(['media.max_kb.document' => 25600]);
        $this->uploadMedia($admin, 'document', $this->pngFile(), 'private')
            ->assertUnprocessable()
            ->assertJsonPath('code', 'MEDIA_MIME_NOT_ALLOWED');
        $this->uploadMedia($admin, 'avatar', $this->svgFile(), 'public')
            ->assertUnprocessable()
            ->assertJsonPath('code', 'MEDIA_MIME_NOT_ALLOWED');
        $this->uploadMedia($admin, 'document', $this->scriptFile(), 'private')
            ->assertUnprocessable()
            ->assertJsonPath('code', 'MEDIA_MIME_NOT_ALLOWED');
    }

    public function test_database_failure_cleans_up_uploaded_object(): void
    {
        $admin = User::factory()->admin()->create();
        $this->app->instance(AuditLogService::class, new class extends AuditLogService
        {
            public function __construct() {}

            public function record(
                string $action,
                Model $auditable,
                ?User $actor = null,
                ?array $oldValues = null,
                ?array $newValues = null,
                array $metadata = [],
                ?Request $request = null,
            ): AuditLog {
                throw new RuntimeException('Simulated database failure.');
            }
        });

        $service = $this->app->make(MediaUploadService::class);

        try {
            $service->upload($admin, $this->pdfFile(), 'document', 'public', [], request());
            $this->fail('Upload should fail when database transaction fails.');
        } catch (ApiException $exception) {
            $this->assertSame('MEDIA_DATABASE_ERROR', $exception->errorCode);
        }

        $this->assertSame([], Storage::disk('public')->allFiles());
    }

    public function test_public_private_metadata_access_and_content_routes_are_safe(): void
    {
        $owner = User::factory()->student()->approved()->create();
        $other = User::factory()->student()->approved()->create();
        $admin = User::factory()->admin()->create();
        $publicMedia = $this->uploadedMedia($owner, 'avatar', $this->pngFile(), 'public');
        $privateMedia = $this->uploadedMedia($owner, 'speaking_recording', $this->mp3File(), 'private');

        $this->get("/api/v1/public/media/{$publicMedia->id}/content")
            ->assertOk()
            ->assertHeader('X-Content-Type-Options', 'nosniff')
            ->assertHeader('Content-Type', 'image/png');
        $this->get("/api/v1/public/media/{$privateMedia->id}/content")->assertForbidden();

        $this->withToken($this->tokenFor($owner))->getJson("/api/v1/media/{$privateMedia->id}")
            ->assertOk()
            ->assertJsonMissingPath('data.disk')
            ->assertJsonMissingPath('data.path')
            ->assertJsonMissingPath('data.checksum_sha256');
        $this->withToken($this->tokenFor($admin))->getJson("/api/v1/media/{$privateMedia->id}")->assertOk();
        $this->withToken($this->tokenFor($other))->getJson("/api/v1/media/{$privateMedia->id}")->assertForbidden();
        $this->withToken($this->tokenFor($other))->getJson("/api/v1/media/{$publicMedia->id}")->assertOk();

        $privateMedia->delete();
        $this->withToken($this->tokenFor($owner))->getJson("/api/v1/media/{$privateMedia->id}")->assertNotFound();
    }

    public function test_temporary_signed_url_rules_and_local_download(): void
    {
        Carbon::setTestNow('2026-06-16 10:00:00');
        $owner = User::factory()->student()->approved()->create();
        $other = User::factory()->student()->approved()->create();
        $admin = User::factory()->admin()->create();
        $privateMedia = $this->uploadedMedia($owner, 'speaking_recording', $this->mp3File(), 'private');
        $publicMedia = $this->uploadedMedia($owner, 'avatar', $this->pngFile(), 'public');

        $this->withToken($this->tokenFor($other))->postJson("/api/v1/media/{$privateMedia->id}/temporary-url")->assertForbidden();
        $this->withToken($this->tokenFor($owner))->postJson("/api/v1/media/{$privateMedia->id}/temporary-url", [
            'expires_in_minutes' => 0,
        ])->assertUnprocessable();
        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/media/{$privateMedia->id}/temporary-url", [
            'expires_in_minutes' => 61,
        ])->assertUnprocessable();
        $this->withToken($this->tokenFor($owner))->postJson("/api/v1/media/{$publicMedia->id}/temporary-url")->assertConflict();

        $response = $this->withToken($this->tokenFor($owner))->postJson("/api/v1/media/{$privateMedia->id}/temporary-url", [
            'expires_in_minutes' => 1,
            'disposition' => 'attachment',
        ])->assertOk();

        $url = $response->json('data.url');
        $this->get($this->pathAndQuery($url))->assertOk()->assertHeader('X-Content-Type-Options', 'nosniff');

        $otherPrivate = $this->uploadedMedia($other, 'speaking_recording', $this->mp3File('other.mp3'), 'private');
        $tampered = str_replace($privateMedia->id, $otherPrivate->id, $this->pathAndQuery($url));
        $this->get($tampered)->assertForbidden();

        Carbon::setTestNow('2026-06-16 10:02:00');
        $this->get($this->pathAndQuery($url))->assertForbidden();
        Carbon::setTestNow();
    }

    public function test_delete_authorization_usage_soft_delete_storage_failure_and_audit(): void
    {
        $owner = User::factory()->teacher()->approved()->create();
        $other = User::factory()->teacher()->approved()->create();
        $admin = User::factory()->admin()->create();
        $media = $this->uploadedMedia($owner, 'document', $this->pdfFile(), 'private');

        $this->withToken($this->tokenFor($other))->deleteJson("/api/v1/media/{$media->id}")->assertForbidden();
        $this->withToken($this->tokenFor($owner))->deleteJson("/api/v1/media/{$media->id}")->assertOk();
        $this->assertSoftDeleted('media_files', ['id' => $media->id]);
        Storage::disk('local')->assertMissing($media->path);
        $this->assertDatabaseHas('audit_logs', ['action' => 'media.deleted']);

        $adminMedia = $this->uploadedMedia($owner, 'document', $this->pdfFile('admin.pdf'), 'private');
        $this->withToken($this->tokenFor($admin))->deleteJson("/api/v1/media/{$adminMedia->id}")->assertOk();

        $avatarMedia = $this->uploadedMedia($owner, 'avatar', $this->pngFile(), 'public');
        $owner->forceFill(['avatar_media_id' => $avatarMedia->id])->save();
        $this->withToken($this->tokenFor($owner))->deleteJson("/api/v1/media/{$avatarMedia->id}")
            ->assertConflict()
            ->assertJsonPath('code', 'MEDIA_IN_USE');

        $missingObject = MediaFile::factory()->private()->create([
            'uploaded_by' => $owner->id,
            'disk' => 'local',
            'path' => 'media/document/missing.pdf',
        ]);
        $this->withToken($this->tokenFor($owner))->deleteJson("/api/v1/media/{$missingObject->id}")
            ->assertStatus(503)
            ->assertJsonPath('code', 'MEDIA_STORAGE_ERROR');
        $this->assertDatabaseHas('media_files', ['id' => $missingObject->id, 'deleted_at' => null]);
    }

    public function test_avatar_upload_replace_remove_idempotency_safe_resource_and_shared_old_avatar(): void
    {
        $user = User::factory()->student()->approved()->create();
        $otherUser = User::factory()->student()->approved()->create();

        $first = $this->withToken($this->tokenFor($user))->post('/api/v1/auth/me/avatar', [
            'avatar' => $this->pngFile('avatar-one.png'),
        ])->assertCreated()
            ->assertJsonPath('data.avatar.url', Storage::disk('public')->url(MediaFile::query()->firstOrFail()->path))
            ->assertJsonMissingPath('data.avatar.disk');

        $firstMedia = MediaFile::query()->findOrFail($first->json('data.avatar.id'));
        $this->assertSame($firstMedia->id, $user->refresh()->avatar_media_id);
        $this->assertDatabaseHas('audit_logs', ['action' => 'user.avatar_updated']);

        $this->withToken($this->tokenFor($user))->post('/api/v1/auth/me/avatar', [
            'avatar' => $this->pngFile('avatar-two.png'),
        ])->assertCreated();
        $this->assertSoftDeleted('media_files', ['id' => $firstMedia->id]);
        Storage::disk('public')->assertMissing($firstMedia->path);
        $this->assertNotSame($firstMedia->id, $user->refresh()->avatar_media_id);

        $shared = $this->uploadedMedia($user, 'avatar', $this->pngFile('shared.png'), 'public');
        $user->forceFill(['avatar_media_id' => $shared->id])->save();
        $otherUser->forceFill(['avatar_media_id' => $shared->id])->save();
        $this->withToken($this->tokenFor($user))->post('/api/v1/auth/me/avatar', [
            'avatar' => $this->pngFile('avatar-three.png'),
        ])->assertCreated();
        $this->assertDatabaseHas('media_files', ['id' => $shared->id, 'deleted_at' => null]);
        Storage::disk('public')->assertExists($shared->path);

        $this->withToken($this->tokenFor($user))->deleteJson('/api/v1/auth/me/avatar')
            ->assertOk()
            ->assertJsonPath('data.avatar', null);
        $this->assertNull($user->refresh()->avatar_media_id);
        $this->assertDatabaseHas('audit_logs', ['action' => 'user.avatar_removed']);
        $this->withToken($this->tokenFor($user))->deleteJson('/api/v1/auth/me/avatar')->assertOk();
    }

    public function test_private_speaking_recording_is_not_accessible_by_other_student_or_teacher_uuid(): void
    {
        $studentA = User::factory()->student()->approved()->create();
        $studentB = User::factory()->student()->approved()->create();
        $teacher = User::factory()->teacher()->approved()->create();
        $recording = $this->uploadedMedia($studentA, 'speaking_recording', $this->mp3File(), 'private');

        $this->withToken($this->tokenFor($studentB))->getJson("/api/v1/media/{$recording->id}")->assertForbidden();
        $this->withToken($this->tokenFor($teacher))->getJson("/api/v1/media/{$recording->id}")->assertForbidden();
        $this->get("/api/v1/public/media/{$recording->id}/content")->assertForbidden();
    }

    private function uploadMedia(User $user, string $purpose, UploadedFile $file, string $visibility, array $extra = [])
    {
        return $this->withToken($this->tokenFor($user))->post('/api/v1/media', array_merge([
            'file' => $file,
            'purpose' => $purpose,
            'visibility' => $visibility,
        ], $extra));
    }

    private function uploadedMedia(User $user, string $purpose, UploadedFile $file, string $visibility): MediaFile
    {
        $response = $this->uploadMedia($user, $purpose, $file, $visibility)->assertCreated();

        return MediaFile::query()->findOrFail($response->json('data.id'));
    }

    private function fileForPurpose(string $purpose): UploadedFile
    {
        return match ($purpose) {
            'avatar', 'question_image' => $this->pngFile(),
            'document' => $this->pdfFile(),
            'audio', 'speaking_recording' => $this->mp3File(),
            default => $this->pdfFile(),
        };
    }

    private function pngFile(string $name = 'avatar.png'): UploadedFile
    {
        return UploadedFile::fake()->createWithContent($name, base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII='));
    }

    private function pdfFile(string $name = 'materi.pdf'): UploadedFile
    {
        return UploadedFile::fake()->createWithContent($name, $this->pdfContent());
    }

    private function pdfContent(): string
    {
        return "%PDF-1.4\n1 0 obj\n<<>>\nendobj\ntrailer\n<<>>\n%%EOF";
    }

    private function mp3File(string $name = 'audio.mp3'): UploadedFile
    {
        return UploadedFile::fake()->createWithContent($name, "ID3\x03\x00\x00\x00\x00\x00\x00");
    }

    private function svgFile(): UploadedFile
    {
        return UploadedFile::fake()->createWithContent('bad.svg', '<svg><script>alert(1)</script></svg>');
    }

    private function scriptFile(): UploadedFile
    {
        return UploadedFile::fake()->createWithContent('bad.php', '<?php echo "bad";');
    }

    private function pathAndQuery(string $url): string
    {
        $parts = parse_url($url);

        return ($parts['path'] ?? '/').(isset($parts['query']) ? '?'.$parts['query'] : '');
    }

    private function tokenFor(User $user): string
    {
        $this->app['auth']->forgetGuards();

        return $user->createToken('PHPUnit')->plainTextToken;
    }
}
