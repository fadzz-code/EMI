<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminSeeder extends Seeder
{
    public function run(): void
    {
        $name = config('services.emi_admin.name', 'Administrator EMI');
        $email = config('services.emi_admin.email', 'admin@example.com');
        $password = config('services.emi_admin.password');

        if (blank($password)) {
            $this->command?->warn('Admin EMI tidak dibuat karena EMI_ADMIN_PASSWORD kosong.');

            return;
        }

        User::query()->updateOrCreate(
            ['email' => $email],
            [
                'full_name' => $name,
                'password' => Hash::make($password),
                'role' => 'admin',
                'status' => 'approved',
                'approved_at' => now(),
                'rejected_reason' => null,
            ],
        );
    }
}
