<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Jobs\DeleteStoredFiles;
use App\Models\MediaFile;
use App\Models\SpeakingAttempt;
use App\Models\User;
use Illuminate\Support\Facades\DB;
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

        $user->forceFill([
            'password' => $data['password'],
            'password_must_change' => false,
        ])->save();

        return $user->refresh();
    }

    public function deleteAccount(User $user, array $data): void
    {
        if (! Hash::check($data['current_password'], $user->password)) {
            throw new ApiException('Password lama tidak sesuai.', 'INVALID_CURRENT_PASSWORD', 422, [
                'current_password' => ['Password lama tidak sesuai.'],
            ]);
        }

        if ($user->role === 'admin') {
            $otherAdmins = User::query()
                ->where('role', 'admin')
                ->where('status', 'approved')
                ->whereKeyNot($user->id)
                ->exists();

            if (! $otherAdmins) {
                throw new ApiException('Admin terakhir tidak dapat menghapus akun sendiri.', 'LAST_ADMIN_ACCOUNT', 409);
            }
        }

        $files = [];

        DB::transaction(function () use ($user, &$files): void {
            $oldEmail = $user->email;
            $attempts = SpeakingAttempt::withTrashed()->where('student_id', $user->id)->get();
            $personalMediaIds = $attempts->pluck('audio_media_id')->filter();
            if ($user->avatar_media_id) {
                $personalMediaIds->push($user->avatar_media_id);
            }

            $media = MediaFile::withTrashed()
                ->whereIn('id', $personalMediaIds->unique())
                ->where('uploaded_by', $user->id)
                ->whereIn('purpose', ['avatar', 'speaking_recording'])
                ->get();
            $files = $media->map(fn (MediaFile $item): array => ['disk' => $item->disk, 'path' => $item->path])
                ->merge($attempts->filter(fn (SpeakingAttempt $attempt): bool => (bool) $attempt->audio_path)
                    ->map(fn (SpeakingAttempt $attempt): array => ['disk' => $attempt->audio_disk ?: 'local', 'path' => $attempt->audio_path]))
                ->unique(fn (array $file): string => $file['disk'].'|'.$file['path'])
                ->values()
                ->all();

            $user->teacherClassAssignments()->where('is_active', true)->update(['is_active' => false, 'ended_at' => now()]);
            $user->studentClassMemberships()->where('is_active', true)->update(['is_active' => false, 'ended_at' => now()]);
            DB::table('password_reset_tokens')->where('email', $oldEmail)->delete();
            DB::table('sessions')->where('user_id', $user->id)->delete();
            DB::table('registration_requests')->where('reviewed_by', $user->id)->update(['reviewed_by' => null]);
            DB::table('registration_requests')->where('user_id', $user->id)->delete();
            DB::table('password_reset_requests')->where('reviewed_by', $user->id)->update(['reviewed_by' => null]);
            DB::table('password_reset_requests')->where('user_id', $user->id)->orWhere('requested_by', $user->id)->delete();
            DB::table('chatbot_conversations')->where('user_id', $user->id)->delete();
            SpeakingAttempt::withTrashed()->where('student_id', $user->id)->forceDelete();
            DB::table('users')->where('id', $user->id)->update(['avatar_media_id' => null]);
            MediaFile::withTrashed()->whereIn('id', $media->pluck('id'))->forceDelete();
            DB::table('audit_logs')->where('actor_id', $user->id)->update([
                'old_values' => null, 'new_values' => null, 'metadata' => null, 'ip_address' => null, 'user_agent' => null,
            ]);
            DB::table('admin_activity_logs')->where('admin_id', $user->id)->update(['properties' => null]);
            $user->forceFill([
                'full_name' => 'Pengguna Dihapus',
                'email' => "deleted+{$user->id}@invalid.local",
                'email_verified_at' => null,
                'password' => bin2hex(random_bytes(32)),
                'password_must_change' => false,
                'phone' => null,
                'avatar_media_id' => null,
                'status' => 'inactive',
                'remember_token' => null,
                'rejected_reason' => null,
                'last_login_at' => null,
                'privacy_policy_accepted_at' => null,
                'privacy_policy_version' => null,
            ])->save();
            $user->tokens()->delete();
        });

        DeleteStoredFiles::dispatch($files)->afterCommit();
    }
}
