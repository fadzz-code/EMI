<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class DevAccountSeeder extends Seeder
{
    public function run(): void
    {
        $accounts = [
            [
                'full_name' => 'Admin EMI',
                'email' => 'admin@emi.test',
                'password' => 'password123',
                'role' => 'admin',
                'status' => 'approved',
            ],
            [
                'full_name' => 'Guru EMI',
                'email' => 'guru@emi.test',
                'password' => 'password123',
                'role' => 'teacher',
                'status' => 'approved',
            ],
            [
                'full_name' => 'Siswa EMI',
                'email' => 'siswa@emi.test',
                'password' => 'password123',
                'role' => 'student',
                'status' => 'approved',
            ],
        ];

        foreach ($accounts as $account) {
            $user = User::query()->where('email', $account['email'])->first();

            if ($user) {
                $user->update([
                    'full_name' => $account['full_name'],
                    'password' => Hash::make($account['password']),
                    'role' => $account['role'],
                    'status' => $account['status'],
                    'email_verified_at' => now(),
                    'approved_at' => now(),
                    'updated_at' => now(),
                ]);
            } else {
                $user = new User;
                $user->id = (string) Str::uuid();
                $user->full_name = $account['full_name'];
                $user->email = $account['email'];
                $user->password = Hash::make($account['password']);
                $user->role = $account['role'];
                $user->status = $account['status'];
                $user->email_verified_at = now();
                $user->approved_at = now();
                $user->save();
            }
        }
    }
}
