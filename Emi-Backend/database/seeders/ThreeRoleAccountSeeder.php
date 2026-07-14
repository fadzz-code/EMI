<?php

namespace Database\Seeders;

use App\Models\School;
use App\Models\SchoolClass;
use App\Models\StudentClassMembership;
use App\Models\TeacherClassAssignment;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use InvalidArgumentException;

class ThreeRoleAccountSeeder extends Seeder
{
    public function run(): void
    {
        if (! app()->environment('local', 'testing', 'development')) {
            throw new InvalidArgumentException('Seeder akun demo statis hanya boleh dijalankan di environment local atau testing.');
        }

        DB::transaction(function () {
            $admin = $this->upsertAccount('admin@emi.test', 'Administrator EMI', 'admin', null);

            // Minimal dependency for Teacher and Student to fully access their dashboard features:
            // They need an active school and class assignment/membership.
            // Without an active class, the frontend might show empty placeholders or fail to load scoped resources.
            $school = School::firstOrCreate(
                ['name' => 'SMP Negeri 1 Kolaka'],
                [
                    'address' => 'Jl. Pendidikan Kolaka',
                    'status' => 'active',
                    'created_by' => $admin->id,
                ]
            );

            if ($school->status !== 'active') {
                $school->update(['status' => 'active']);
            }

            $class = SchoolClass::firstOrCreate(
                [
                    'school_id' => $school->id,
                    'name' => 'Kelas VII A',
                ],
                [
                    'grade_level' => '7',
                    'academic_year' => '2026/2027',
                    'status' => 'active',
                    'created_by' => $admin->id,
                ]
            );

            if ($class->status !== 'active') {
                $class->update(['status' => 'active']);
            }

            $teacher = $this->upsertAccount('teacher@emi.test', 'Guru Demo EMI', 'teacher', $admin->id);

            TeacherClassAssignment::updateOrCreate(
                [
                    'teacher_id' => $teacher->id,
                    'class_id' => $class->id,
                ],
                [
                    'is_active' => true,
                    'assigned_by' => $admin->id,
                    'assigned_at' => now(),
                ]
            );

            $student = $this->upsertAccount('student@emi.test', 'Siswa Demo EMI', 'student', $admin->id);

            StudentClassMembership::updateOrCreate(
                [
                    'student_id' => $student->id,
                    'class_id' => $class->id,
                ],
                [
                    'is_active' => true,
                    'assigned_by' => $admin->id,
                    'joined_at' => now(),
                ]
            );

            // Revoke active tokens so they are forced to re-login with the new password
            $admin->tokens()->delete();
            $teacher->tokens()->delete();
            $student->tokens()->delete();
        });
    }

    private function upsertAccount(string $email, string $name, string $role, ?string $adminId): User
    {
        $user = User::updateOrCreate(
            ['email' => $email],
            [
                'full_name' => $name,
                'password' => Hash::make('12345678'),
                'role' => $role,
                'status' => 'approved',
                'phone' => null,
                'email_verified_at' => now(),
                'approved_by' => $adminId,
                'approved_at' => now(),
                'rejected_reason' => null,
            ]
        );

        return $user;
    }
}
