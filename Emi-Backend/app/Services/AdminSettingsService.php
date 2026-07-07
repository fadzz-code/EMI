<?php

namespace App\Services;

use App\Models\AdminActivityLog;
use App\Models\MediaFile;
use App\Models\SystemSetting;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;

class AdminSettingsService
{
    public function __construct(private readonly MediaUploadService $mediaUploadService) {}

    public function get(): array
    {
        $settings = SystemSetting::query()->pluck('value', 'key');

        return [
            'application' => $settings->get('application', $this->defaults()['application']),
            'banner' => $this->bannerData($settings->get('banner', $this->defaults()['banner'])),
            'security' => $settings->get('security', $this->defaults()['security']),
            'activity_logs' => $this->logs(),
        ];
    }

    public function publicBranding(): array
    {
        $banner = $this->bannerData(SystemSetting::query()->find('banner')?->value ?? $this->defaults()['banner']);

        return [
            'enabled' => (bool) ($banner['enabled'] ?? false),
            'image_url' => $banner['enabled'] ? ($banner['image_url'] ?? null) : null,
        ];
    }

    public function updateApplication(User $admin, array $data): array
    {
        return $this->save('application', $data, $admin, 'settings.application.updated', 'Pengaturan aplikasi diperbarui');
    }

    public function updateSecurity(User $admin, array $data): array
    {
        return $this->save('security', $data, $admin, 'settings.security.updated', 'Preferensi keamanan diperbarui');
    }

    public function updateBanner(User $admin, array $data, ?UploadedFile $file, Request $request): array
    {
        return DB::transaction(function () use ($admin, $data, $file, $request) {
            $current = SystemSetting::query()->find('banner')?->value ?? $this->defaults()['banner'];

            if ($file) {
                $media = $this->mediaUploadService->upload($admin, $file, 'login_banner', 'public', [], $request);
                $data['image_media_id'] = $media->id;
            } else {
                $data['image_media_id'] = $current['image_media_id'] ?? null;
            }

            $value = array_merge($current, $data);
            SystemSetting::query()->updateOrCreate(['key' => 'banner'], ['value' => $value]);
            $this->log($admin, 'settings.banner.updated', $value['title'] ?? 'Banner login diperbarui', ['enabled' => (bool) ($value['enabled'] ?? false)]);

            return $this->bannerData($value);
        });
    }

    private function save(string $key, array $data, User $admin, string $action, string $title): array
    {
        SystemSetting::query()->updateOrCreate(['key' => $key], ['value' => $data]);
        $this->log($admin, $action, $title, $data);

        return $data;
    }

    private function bannerData(array $banner): array
    {
        $media = isset($banner['image_media_id']) ? MediaFile::query()->active()->find($banner['image_media_id']) : null;
        $banner['image_url'] = $media ? url("/api/v1/public/media/{$media->id}/content") : null;

        return $banner;
    }

    private function logs(): array
    {
        return AdminActivityLog::query()->with('admin')->latest()->limit(20)->get()->map(fn (AdminActivityLog $log) => [
            'id' => $log->id,
            'created_at' => $log->created_at?->toISOString(),
            'admin' => $log->admin?->full_name ?? 'Admin',
            'action' => $log->action,
            'title' => $log->title,
            'status' => (bool) data_get($log->properties, 'enabled', true),
        ])->all();
    }

    private function log(User $admin, string $action, string $title, array $properties): void
    {
        AdminActivityLog::query()->create([
            'admin_id' => $admin->id,
            'action' => $action,
            'title' => $title,
            'properties' => $properties,
        ]);
    }

    private function defaults(): array
    {
        return [
            'application' => [
                'name' => 'EMI',
                'subtitle' => 'Belajar Bahasa Mekongga',
                'active_academic_year' => now()->year.'/'.now()->addYear()->year,
                'timezone' => config('app.timezone'),
            ],
            'banner' => [
                'enabled' => false,
                'title' => '',
                'subtitle' => '',
                'image_media_id' => null,
            ],
            'security' => [
                'new_login_alert' => false,
                'weekly_report_email' => false,
            ],
        ];
    }
}
