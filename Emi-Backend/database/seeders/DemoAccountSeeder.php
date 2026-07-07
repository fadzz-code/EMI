<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DemoAccountSeeder extends Seeder
{
    use DemoSeederSupport;

    public function run(): void
    {
        $password = env('EMI_DEMO_PASSWORD');

        if (! $password && app()->environment('local', 'testing', 'development')) {
            $password = 'DemoPassword123';
        }

        if (! $password) {
            $this->command?->warn('EMI_DEMO_PASSWORD kosong. DemoAccountSeeder dilewati.');

            return;
        }

        $admin = $this->user('Admin Demo EMI', 'admin.demo@emi.local', 'admin', 'approved', $password, null);

        foreach ($this->users() as $user) {
            $this->user($user['name'], $user['email'], $user['role'], $user['status'], $password, $admin->id, $user['reason'] ?? null);
        }
    }

    private function user(string $name, string $email, string $role, string $status, string $password, ?string $adminId, ?string $reason = null): User
    {
        return $this->upsertModel(User::class, ['email' => $email], [
            'full_name' => $name,
            'password' => Hash::make($password),
            'role' => $role,
            'status' => $status,
            'phone' => null,
            'email_verified_at' => now(),
            'approved_by' => $status === 'approved' || $status === 'inactive' ? $adminId : null,
            'approved_at' => $status === 'approved' || $status === 'inactive' ? now() : null,
            'rejected_reason' => $reason,
        ]);
    }

    private function users(): array
    {
        return [
            ['name' => 'Guru Rina Mekongga', 'email' => 'guru.rina@emi.local', 'role' => 'teacher', 'status' => 'approved'],
            ['name' => 'Guru Arman Kolaka', 'email' => 'guru.arman@emi.local', 'role' => 'teacher', 'status' => 'approved'],
            ['name' => 'Nanda Saputra', 'email' => 'siswa.nanda@emi.local', 'role' => 'student', 'status' => 'approved'],
            ['name' => 'Mira Lestari', 'email' => 'siswa.mira@emi.local', 'role' => 'student', 'status' => 'approved'],
            ['name' => 'Rafi Pratama', 'email' => 'siswa.rafi@emi.local', 'role' => 'student', 'status' => 'approved'],
            ['name' => 'Guru Pending Demo', 'email' => 'guru.pending@emi.local', 'role' => 'teacher', 'status' => 'pending'],
            ['name' => 'Siswa Rejected Demo', 'email' => 'siswa.rejected@emi.local', 'role' => 'student', 'status' => 'rejected', 'reason' => 'Data demo ditolak untuk pengujian status.'],
            ['name' => 'Siswa Inactive Demo', 'email' => 'siswa.inactive@emi.local', 'role' => 'student', 'status' => 'inactive'],
        ];
    }
}
