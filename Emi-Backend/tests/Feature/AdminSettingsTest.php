<?php

namespace Tests\Feature;

use App\Models\SystemSetting;
use App\Models\User;
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

    public function test_admin_can_get_settings(): void
    {
        $admin = User::factory()->admin()->create();

        Sanctum::actingAs($admin);

        $this->getJson('/api/v1/admin/settings')
            ->assertOk()
            ->assertJsonPath('data.application.name', 'EMI')
            ->assertJsonStructure(['data' => ['application', 'banner', 'security', 'activity_logs']]);
    }

    public function test_admin_can_update_application_settings_and_activity_log_is_recorded(): void
    {
        $admin = User::factory()->admin()->create();

        Sanctum::actingAs($admin);

        $this->putJson('/api/v1/admin/settings/application', [
            'name' => 'EMI Mekongga',
            'subtitle' => 'Bahasa Mekongga',
            'active_academic_year' => '2026/2027',
            'timezone' => 'Asia/Makassar',
        ])->assertOk()->assertJsonPath('data.name', 'EMI Mekongga');

        $this->assertSame('EMI Mekongga', SystemSetting::query()->find('application')->value['name']);
        $this->assertDatabaseHas('admin_activity_logs', ['action' => 'settings.application.updated']);
    }

    public function test_admin_can_update_login_banner(): void
    {
        $admin = User::factory()->admin()->create();

        Sanctum::actingAs($admin);

        $path = tempnam(sys_get_temp_dir(), 'banner');
        file_put_contents($path, base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII='));

        $this->postJson('/api/v1/admin/settings/banner', [
            'enabled' => true,
            'file' => new UploadedFile($path, 'banner.png', 'image/png', null, true),
        ])->assertOk()
            ->assertJsonPath('data.enabled', true)
            ->assertJsonStructure(['data' => ['image_url']]);

        $this->assertDatabaseHas('media_files', ['purpose' => 'login_banner', 'visibility' => 'public']);
    }

    public function test_non_admin_cannot_update_settings(): void
    {
        $teacher = User::factory()->teacher()->approved()->create();

        Sanctum::actingAs($teacher);

        $this->putJson('/api/v1/admin/settings/security', [
            'new_login_alert' => true,
            'weekly_report_email' => false,
        ])->assertForbidden();
    }

    public function test_public_login_branding_only_returns_safe_data(): void
    {
        SystemSetting::query()->create(['key' => 'security', 'value' => ['new_login_alert' => true]]);
        SystemSetting::query()->create(['key' => 'banner', 'value' => ['enabled' => true, 'title' => 'Halo', 'subtitle' => 'Masuk', 'image_media_id' => null]]);

        $this->getJson('/api/v1/public/login-branding')
            ->assertOk()
            ->assertJsonPath('data.enabled', true)
            ->assertJsonMissing(['new_login_alert', 'title', 'subtitle']);
    }

    public function test_admin_can_update_security_preferences(): void
    {
        $admin = User::factory()->admin()->create();

        Sanctum::actingAs($admin);

        $this->putJson('/api/v1/admin/settings/security', [
            'new_login_alert' => true,
            'weekly_report_email' => true,
        ])->assertOk()->assertJsonPath('data.weekly_report_email', true);

        $this->assertTrue(SystemSetting::query()->find('security')->value['new_login_alert']);
    }

    public function test_updates_only_store_validated_fields(): void
    {
        $admin = User::factory()->admin()->create();

        Sanctum::actingAs($admin);

        $this->putJson('/api/v1/admin/settings/application', [
            'name' => 'EMI Aman',
            'subtitle' => null,
            'active_academic_year' => '2026/2027',
            'timezone' => 'Asia/Makassar',
            'unknown' => 'discarded',
        ])->assertOk()->assertJsonMissing(['unknown' => 'discarded']);

        $this->putJson('/api/v1/admin/settings/security', [
            'new_login_alert' => false,
            'weekly_report_email' => true,
            'unknown' => true,
        ])->assertOk()->assertJsonPath('data.new_login_alert', false);

        $this->assertArrayNotHasKey('unknown', SystemSetting::query()->find('application')->value);
        $this->assertArrayNotHasKey('unknown', SystemSetting::query()->find('security')->value);
    }

    public function test_application_and_security_updates_require_complete_valid_payloads(): void
    {
        $admin = User::factory()->admin()->create();
        SystemSetting::query()->create(['key' => 'application', 'value' => ['name' => 'Old']]);

        Sanctum::actingAs($admin);

        $this->putJson('/api/v1/admin/settings/application', [
            'name' => '',
            'active_academic_year' => '2026/2027',
            'timezone' => 'Not/A_Timezone',
        ])->assertUnprocessable()->assertJsonValidationErrors(['name', 'timezone']);

        $this->putJson('/api/v1/admin/settings/application', [
            'name' => 'Partial',
        ])->assertUnprocessable()->assertJsonValidationErrors(['active_academic_year', 'timezone']);

        $this->putJson('/api/v1/admin/settings/security', [
            'new_login_alert' => 'yes',
        ])->assertUnprocessable()->assertJsonValidationErrors(['new_login_alert', 'weekly_report_email']);

        $this->assertSame(['name' => 'Old'], SystemSetting::query()->find('application')->value);
        $this->assertDatabaseMissing('admin_activity_logs', ['action' => 'settings.application.updated']);
        $this->assertDatabaseMissing('admin_activity_logs', ['action' => 'settings.security.updated']);
    }

    public function test_banner_requires_boolean_and_empty_upload_retains_existing_media(): void
    {
        $admin = User::factory()->admin()->create();
        SystemSetting::query()->create(['key' => 'banner', 'value' => [
            'enabled' => true,
            'title' => 'Existing',
            'subtitle' => 'Existing subtitle',
            'image_media_id' => '00000000-0000-4000-8000-000000000001',
        ]]);

        Sanctum::actingAs($admin);

        $this->postJson('/api/v1/admin/settings/banner', [])->assertUnprocessable()->assertJsonValidationErrors('enabled');
        $this->postJson('/api/v1/admin/settings/banner', ['enabled' => 'yes'])->assertUnprocessable()->assertJsonValidationErrors('enabled');
        $this->postJson('/api/v1/admin/settings/banner', [
            'enabled' => false,
            'file' => null,
            'unknown' => 'discarded',
        ])->assertOk()->assertJsonPath('data.enabled', false);

        $banner = SystemSetting::query()->find('banner')->value;
        $this->assertSame('00000000-0000-4000-8000-000000000001', $banner['image_media_id']);
        $this->assertSame('Existing', $banner['title']);
        $this->assertArrayNotHasKey('file', $banner);
        $this->assertArrayNotHasKey('unknown', $banner);
    }

    public function test_admin_settings_routes_require_admin_authentication(): void
    {
        $routes = [
            ['getJson', '/api/v1/admin/settings', []],
            ['putJson', '/api/v1/admin/settings/application', []],
            ['postJson', '/api/v1/admin/settings/banner', []],
            ['putJson', '/api/v1/admin/settings/security', []],
        ];

        foreach ($routes as [$method, $uri, $payload]) {
            $this->{$method}($uri, $payload)->assertUnauthorized();
        }

        foreach ([User::factory()->teacher()->approved()->create(), User::factory()->student()->approved()->create()] as $user) {
            Sanctum::actingAs($user);

            foreach ($routes as [$method, $uri, $payload]) {
                $this->{$method}($uri, $payload)->assertForbidden();
            }
        }
    }

    public function test_public_branding_response_has_only_safe_fields(): void
    {
        SystemSetting::query()->create(['key' => 'application', 'value' => ['name' => 'Private application']]);
        SystemSetting::query()->create(['key' => 'security', 'value' => ['new_login_alert' => true, 'weekly_report_email' => true]]);
        SystemSetting::query()->create(['key' => 'banner', 'value' => [
            'enabled' => false,
            'title' => 'Private title',
            'subtitle' => 'Private subtitle',
            'image_media_id' => null,
        ]]);

        $this->getJson('/api/v1/public/login-branding')
            ->assertOk()
            ->assertExactJson([
                'success' => true,
                'message' => 'Branding login berhasil diambil.',
                'data' => ['enabled' => false, 'image_url' => null],
            ]);
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
