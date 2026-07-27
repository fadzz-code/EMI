<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\ForgotPasswordRequest;
use App\Models\User;
use App\Services\PasswordResetApprovalService;
use Illuminate\Http\JsonResponse;

class PasswordResetController extends Controller
{
    private const GENERIC_MESSAGE = 'Jika email terdaftar, permintaan reset password akan diproses.';

    private const ADMIN_MESSAGE = 'Reset password admin tidak dapat dilakukan lewat email. Minta admin lain untuk mereset password Anda dari menu Guru & Siswa, atau hubungi tim teknis untuk reset via server jika tidak ada admin lain yang bisa login.';

    public function __construct(private readonly PasswordResetApprovalService $approvalService) {}

    public function forgot(ForgotPasswordRequest $request): JsonResponse
    {
        $user = User::query()->where('email', $request->validated('email'))->first();

        if (! $user) {
            return ApiResponse::success(self::GENERIC_MESSAGE, []);
        }

        if ($user->role === 'admin') {
            return ApiResponse::success(self::ADMIN_MESSAGE, []);
        }

        try {
            $this->approvalService->request($user, $user, $request);
        } catch (\Throwable) {
            // Permintaan sudah pending sebelumnya atau gagal dibuat: tetap balas pesan generik
            // agar tidak membocorkan status akun ke pemanggil yang tidak diautentikasi.
        }

        return ApiResponse::success(self::GENERIC_MESSAGE, []);
    }
}
