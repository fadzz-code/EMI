<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\DeleteAccountRequest;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Requests\Auth\UpdatePasswordRequest;
use App\Http\Requests\Auth\UpdateProfileRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Services\AuthService;
use App\Services\PasswordResetApprovalService;
use App\Services\RegistrationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    public function __construct(
        private readonly RegistrationService $registrationService,
        private readonly AuthService $authService,
        private readonly PasswordResetApprovalService $passwordResetApprovalService,
    ) {}

    public function register(RegisterRequest $request): JsonResponse
    {
        $user = $this->registrationService->register($request->validated());

        return ApiResponse::success('Pendaftaran berhasil. Akun menunggu persetujuan Admin.', [
            'user_id' => $user->id,
            'status' => $user->status,
        ], 201);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $login = $this->authService->login($request->validated());

        return ApiResponse::success('Login berhasil.', [
            'token' => $login['token'],
            'token_type' => 'Bearer',
            'user' => new UserResource($this->loadProfile($login['user'])),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $this->authService->logout($request->user(), $request->bearerToken());

        return ApiResponse::success('Logout berhasil.', []);
    }

    public function me(Request $request): JsonResponse
    {
        return ApiResponse::success('Profil berhasil diambil.', new UserResource($this->loadProfile($request->user())));
    }

    public function updateProfile(UpdateProfileRequest $request): JsonResponse
    {
        $user = $this->authService->updateProfile($request->user(), $request->validated());

        return ApiResponse::success('Profil berhasil diperbarui.', new UserResource($this->loadProfile($user)));
    }

    public function updatePassword(UpdatePasswordRequest $request): JsonResponse
    {
        $user = $this->authService->updatePassword($request->user(), $request->validated());

        return ApiResponse::success('Password berhasil diperbarui.', new UserResource($this->loadProfile($user)));
    }

    public function deleteAccount(DeleteAccountRequest $request): JsonResponse
    {
        $this->authService->deleteAccount($request->user(), $request->validated());

        return ApiResponse::success('Akun berhasil dinonaktifkan.', []);
    }

    public function requestPasswordResetApproval(Request $request): JsonResponse
    {
        $user = $request->user();

        if ($user->role === 'admin') {
            return ApiResponse::error('Admin dapat mengubah password langsung tanpa persetujuan.', 'ADMIN_NO_APPROVAL_NEEDED', 422);
        }

        $this->passwordResetApprovalService->request($user, $user, $request);

        return ApiResponse::success('Permintaan reset password telah dikirim untuk disetujui guru/admin.', []);
    }

    private function loadProfile(User $user): User
    {
        return $user->load([
            'avatarMedia',
            'activeTeacherClassAssignment.schoolClass.school',
            'activeStudentClassMembership.schoolClass.school',
        ]);
    }
}
