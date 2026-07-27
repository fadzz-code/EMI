<?php

namespace App\Console\Commands;

use App\Models\User;
use App\Services\AuditLogService;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rules\Password;

class ResetAdminPasswordCommand extends Command
{
    protected $signature = 'admin:reset-password {email : Email akun admin yang akan direset}';

    protected $description = 'Reset password akun admin langsung dari server (jalur darurat jika semua admin terkunci dan tidak ada admin lain yang bisa login).';

    public function handle(AuditLogService $auditLogService): int
    {
        $email = trim((string) $this->argument('email'));

        $user = User::query()->where('email', $email)->first();

        if (! $user) {
            $this->error("Akun dengan email \"{$email}\" tidak ditemukan.");

            return self::FAILURE;
        }

        if ($user->role !== 'admin') {
            $this->error("Akun \"{$email}\" bukan akun admin (role: {$user->role}). Perintah ini hanya untuk akun admin.");
            $this->line('Untuk siswa atau guru, gunakan alur persetujuan reset password lewat aplikasi (admin/guru menyetujui dari dashboard).');

            return self::FAILURE;
        }

        $this->info("Akun ditemukan: {$user->full_name} ({$user->email}), status: {$user->status}.");
        $this->newLine();

        $password = $this->secret('Masukkan password baru (minimal 8 karakter, mengandung huruf dan angka)');
        $passwordConfirmation = $this->secret('Ulangi password baru');

        $validator = Validator::make(
            ['password' => $password, 'password_confirmation' => $passwordConfirmation],
            ['password' => ['required', 'confirmed', Password::min(8)->letters()->numbers()]],
            [
                'password.required' => 'Password wajib diisi.',
                'password.min' => 'Password minimal 8 karakter.',
                'password.letters' => 'Password harus mengandung minimal satu huruf.',
                'password.numbers' => 'Password harus mengandung minimal satu angka.',
                'password.confirmed' => 'Konfirmasi password tidak sama.',
            ],
        );

        if ($validator->fails()) {
            foreach ($validator->errors()->all() as $message) {
                $this->error($message);
            }

            return self::FAILURE;
        }

        if (! $this->confirm("Reset password untuk {$user->email} sekarang? Semua sesi login akun ini akan langsung keluar.")) {
            $this->line('Dibatalkan.');

            return self::SUCCESS;
        }

        $user->forceFill([
            'password' => Hash::make($password),
            'password_must_change' => true,
        ])->save();
        $user->tokens()->delete();

        $auditLogService->record('user.password_force_reset', $user, null, [], [
            'reset_via' => 'artisan_command',
        ]);

        $this->newLine();
        $this->info('Password berhasil direset.');
        $this->line('Akun ini wajib mengganti password saat login berikutnya.');

        return self::SUCCESS;
    }
}
