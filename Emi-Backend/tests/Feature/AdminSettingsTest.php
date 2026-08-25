<?php

namespace Tests\Feature;

use App\Models\MediaFile;
use App\Models\SystemSetting;
use App\Models\User;
use App\Services\MediaUsageService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminSettingsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('public');
        config(['media.public_disk' => 'public']);
    }

    public function test_admin_settings_only_return_banner_and_activity_logs(): void
    {
        SystemSetting::query()->create(['key' => 'application', 'value' => ['name' => 'Legacy']]);
        SystemSetting::query()->create(['key' => 'security', 'value' => ['new_login_alert' => true]]);
        SystemSetting::query()->create(['key' => 'banner', 'value' => [
            'enabled' => true,
            'title' => 'Legacy title',
            'subtitle' => 'Legacy subtitle',
            'image_media_id' => null,
        ]]);
        Sanctum::actingAs(User::factory()->admin()->create());

        $this->getJson('/api/v1/admin/settings')->assertOk()->assertExactJson([
            'success' => true,
            'message' => 'Pengaturan berhasil diambil.',
            'data' => [
                'banner' => ['enabled' => true, 'image_media_id' => null, 'image_url' => null],
                'activity_logs' => [],
            ],
        ]);
    }

    public function test_application_and_security_update_routes_are_removed(): void
    {
        Sanctum::actingAs(User::factory()->admin()->create());

        $this->putJson('/api/v1/admin/settings/application', [])->assertNotFound();
        $this->putJson('/api/v1/admin/settings/security', [])->assertNotFound();
    }

    public function test_admin_can_upload_login_banner_with_whitelisted_response(): void
    {
        Sanctum::actingAs(User::factory()->admin()->create());
        $path = tempnam(sys_get_temp_dir(), 'banner');
        file_put_contents($path, base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII='));

        $response = $this->postJson('/api/v1/admin/settings/banner', [
            'enabled' => true,
            'file' => new UploadedFile($path, 'banner.png', 'image/png', null, true),
        ])->assertOk()->assertJsonStructure(['data' => ['enabled', 'image_media_id', 'image_url']]);

        $this->assertSame(['enabled', 'image_media_id', 'image_url'], array_keys($response->json('data')));
        $this->assertDatabaseHas('media_files', ['purpose' => 'login_banner', 'visibility' => 'public']);
    }

    public function test_banner_requires_boolean_and_empty_upload_retains_existing_media(): void
    {
        SystemSetting::query()->create(['key' => 'banner', 'value' => [
            'enabled' => true,
            'title' => 'Legacy',
            'image_media_id' => '00000000-0000-4000-8000-000000000001',
        ]]);
        Sanctum::actingAs(User::factory()->admin()->create());

        $this->postJson('/api/v1/admin/settings/banner', [])->assertUnprocessable()->assertJsonValidationErrors('enabled');
        $this->postJson('/api/v1/admin/settings/banner', ['enabled' => 'yes'])->assertUnprocessable()->assertJsonValidationErrors('enabled');
        $this->postJson('/api/v1/admin/settings/banner', ['enabled' => false, 'file' => null, 'unknown' => true])
            ->assertOk()
            ->assertExactJson([
                'success' => true,
                'message' => 'Banner login berhasil disimpan.',
                'data' => ['enabled' => false, 'image_media_id' => '00000000-0000-4000-8000-000000000001', 'image_url' => null],
            ]);

        $banner = SystemSetting::query()->find('banner')->value;
        $this->assertSame('00000000-0000-4000-8000-000000000001', $banner['image_media_id']);
        $this->assertSame('Legacy', $banner['title']);
        $this->assertArrayNotHasKey('unknown', $banner);
    }

    public function test_public_branding_response_has_only_safe_fields(): void
    {
        SystemSetting::query()->create(['key' => 'application', 'value' => ['name' => 'Private']]);
        SystemSetting::query()->create(['key' => 'security', 'value' => ['new_login_alert' => true]]);
        SystemSetting::query()->create(['key' => 'banner', 'value' => ['enabled' => true, 'title' => 'Private', 'image_media_id' => null]]);

        $this->getJson('/api/v1/public/login-branding')->assertOk()->assertExactJson([
            'success' => true,
            'message' => 'Branding login berhasil diambil.',
            'data' => ['enabled' => true, 'image_url' => null],
        ]);
    }

    public function test_admin_settings_routes_require_admin_authentication(): void
    {
        foreach ([['getJson', '/api/v1/admin/settings'], ['postJson', '/api/v1/admin/settings/banner']] as [$method, $uri]) {
            $this->{$method}($uri, [])->assertUnauthorized();
        }

        Sanctum::actingAs(User::factory()->teacher()->approved()->create());

        foreach ([['getJson', '/api/v1/admin/settings'], ['postJson', '/api/v1/admin/settings/banner']] as [$method, $uri]) {
            $this->{$method}($uri, [])->assertForbidden();
        }
    }

    public function test_banner_media_is_considered_in_use(): void
    {
        $media = MediaFile::factory()->create();
        SystemSetting::query()->create(['key' => 'banner', 'value' => ['enabled' => true, 'image_media_id' => $media->id]]);

        $this->assertTrue(app(MediaUsageService::class)->isInUse($media));
    }

    public function test_password_admin_can_be_changed(): void
    {
        $admin = User::factory()->admin()->create(['password' => 'Password1']);
        Sanctum::actingAs($admin);

        $this->putJson('/api/v1/auth/password', [
            'current_password' => 'Password1',
            'password' => 'Password2',
            'password_confirmation' => 'Password2',
        ])->assertOk();

        $this->assertTrue(Hash::check('Password2', $admin->refresh()->password));
    }
}
