<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\PersonalAccessToken;

class AuthService
{
    public function login(array $data): array
    {
        $user = User::query()->where('email', $data['email'])->first();

        if (! $user || ! Hash::check($data['password'], $user->password)) {
            throw new ApiException('Email atau password salah.', 'INVALID_CREDENTIALS', 401);
        }

        if ($user->status !== 'approved') {
            $message = match ($user->status) {
                'pending' => 'Akun masih menunggu persetujuan Admin.',
                'rejected' => 'Akun ditolak oleh Admin.',
                'inactive' => 'Akun tidak aktif.',
                default => 'Akun belum dapat digunakan.',
            };

            throw new ApiException($message, 'ACCOUNT_NOT_APPROVED', 403);
        }

        $user->forceFill(['last_login_at' => now()])->save();

        return [
            'user' => $user,
            'token' => $user->createToken($data['device_name'])->plainTextToken,
        ];
    }

    public function logout(User $user, ?string $bearerToken = null): void
    {
        $accessToken = $user->currentAccessToken();

        if ($accessToken instanceof PersonalAccessToken) {
            $accessToken->delete();

            return;
        }

        if ($bearerToken) {
            PersonalAccessToken::findToken($bearerToken)?->delete();
        }
    }

    public function updateProfile(User $user, array $data): User
    {
        $user->fill(collect($data)->only(['full_name', 'phone'])->all());
        $user->save();

        return $user->refresh();
    }

    public function updatePassword(User $user, array $data): User
    {
        if (! Hash::check($data['current_password'], $user->password)) {
            throw new ApiException('Password lama tidak sesuai.', 'INVALID_CURRENT_PASSWORD', 422, [
                'current_password' => ['Password lama tidak sesuai.'],
            ]);
        }

        $user->forceFill(['password' => $data['password']])->save();

        return $user->refresh();
    }
}
