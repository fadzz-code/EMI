<?php

namespace Database\Seeders;

use App\Models\RegistrationRequest;
use App\Models\School;
use App\Models\SchoolClass;
use App\Models\StudentClassMembership;
use App\Models\TeacherClassAssignment;
use App\Models\User;
use Illuminate\Database\Seeder;

class DemoSchoolClassSeeder extends Seeder
{
    use DemoSeederSupport;

    public function run(): void
    {
        $admin = User::query()->where('email', 'admin.demo@emi.local')->firstOrFail();
        $rina = User::query()->where('email', 'guru.rina@emi.local')->firstOrFail();
        $arman = User::query()->where('email', 'guru.arman@emi.local')->firstOrFail();
        $nanda = User::query()->where('email', 'siswa.nanda@emi.local')->firstOrFail();
        $mira = User::query()->where('email', 'siswa.mira@emi.local')->firstOrFail();
        $rafi = User::query()->where('email', 'siswa.rafi@emi.local')->firstOrFail();
        $inactive = User::query()->where('email', 'siswa.inactive@emi.local')->firstOrFail();

        $kolaka = $this->upsertModel(School::class, ['name' => 'SMP Negeri Demo Kolaka'], [
            'address' => 'Kolaka, Sulawesi Tenggara',
            'phone' => null,
            'status' => 'active',
            'created_by' => $admin->id,
        ]);
        $wundulako = $this->upsertModel(School::class, ['name' => 'SMP Demo Wundulako'], [
            'address' => 'Wundulako, Kolaka, Sulawesi Tenggara',
            'phone' => null,
            'status' => 'active',
            'created_by' => $admin->id,
        ]);

        $classA = $this->upsertModel(SchoolClass::class, ['school_id' => $kolaka->id, 'name' => 'VII-A Mekongga', 'academic_year' => '2026/2027'], [
            'grade_level' => '7',
            'status' => 'active',
            'created_by' => $admin->id,
        ]);
        $classB = $this->upsertModel(SchoolClass::class, ['school_id' => $wundulako->id, 'name' => 'VIII-B Budaya', 'academic_year' => '2026/2027'], [
            'grade_level' => '8',
            'status' => 'active',
            'created_by' => $admin->id,
        ]);

        $this->assignTeacher($rina, $classA, $admin);
        $this->assignTeacher($arman, $classB, $admin);

        foreach ([$nanda, $mira, $rafi] as $student) {
            $this->assignStudent($student, $classA, $admin);
        }
        $this->assignStudent($inactive, $classB, $admin);

        $this->registrationRequest('guru.pending@emi.local', $classB, 'teacher');
        $this->registrationRequest('siswa.rejected@emi.local', $classA, 'student');
    }

    private function assignTeacher(User $teacher, SchoolClass $class, User $admin): void
    {
        $this->upsertModel(TeacherClassAssignment::class, ['teacher_id' => $teacher->id, 'class_id' => $class->id], [
            'assigned_by' => $admin->id,
            'is_active' => true,
            'assigned_at' => now(),
            'ended_at' => null,
        ]);
    }

    private function assignStudent(User $student, SchoolClass $class, User $admin): void
    {
        $this->upsertModel(StudentClassMembership::class, ['student_id' => $student->id, 'class_id' => $class->id], [
            'assigned_by' => $admin->id,
            'is_active' => true,
            'joined_at' => now(),
            'ended_at' => null,
        ]);
    }

    private function registrationRequest(string $email, SchoolClass $class, string $role): void
    {
        $user = User::query()->where('email', $email)->first();

        if (! $user) {
            return;
        }

        $status = $user->status === 'rejected' ? 'rejected' : 'pending';
        $this->upsertModel(RegistrationRequest::class, ['user_id' => $user->id], [
            'requested_role' => $role,
            'school_id' => $class->school_id,
            'class_id' => $class->id,
            'status' => $status,
            'reviewed_by' => null,
            'reviewed_at' => null,
            'review_note' => $status === 'rejected' ? 'Data demo ditolak untuk pengujian.' : null,
        ]);
    }
}
