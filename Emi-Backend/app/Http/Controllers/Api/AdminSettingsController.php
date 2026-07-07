<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\UpdateApplicationSettingsRequest;
use App\Http\Requests\Admin\UpdateBannerSettingsRequest;
use App\Http\Requests\Admin\UpdateSecuritySettingsRequest;
use App\Services\AdminSettingsService;
use Illuminate\Http\JsonResponse;

class AdminSettingsController extends Controller
{
    public function __construct(private readonly AdminSettingsService $settingsService) {}

    public function show(): JsonResponse
    {
        return ApiResponse::success('Pengaturan berhasil diambil.', $this->settingsService->get());
    }

    public function updateApplication(UpdateApplicationSettingsRequest $request): JsonResponse
    {
        return ApiResponse::success('Pengaturan aplikasi berhasil disimpan.', $this->settingsService->updateApplication($request->user(), $request->validated()));
    }

    public function updateBanner(UpdateBannerSettingsRequest $request): JsonResponse
    {
        return ApiResponse::success('Banner login berhasil disimpan.', $this->settingsService->updateBanner($request->user(), $request->validated(), $request->file('file'), $request));
    }

    public function updateSecurity(UpdateSecuritySettingsRequest $request): JsonResponse
    {
        return ApiResponse::success('Preferensi keamanan berhasil disimpan.', $this->settingsService->updateSecurity($request->user(), $request->validated()));
    }

    public function branding(): JsonResponse
    {
        return ApiResponse::success('Branding login berhasil diambil.', $this->settingsService->publicBranding());
    }
}
