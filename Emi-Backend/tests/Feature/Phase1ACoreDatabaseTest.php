<?php

namespace Tests\Feature;

use App\Models\RegistrationRequest;
use App\Models\School;
use App\Models\SchoolClass;
use App\Models\StudentClassMembership;
use App\Models\TeacherClassAssignment;
use App\Models\User;
use Database\Seeders\AdminSeeder;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Tests\TestCase;

class Phase1ACoreDatabaseTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_seeder_creates_approved_admin(): void
    {
        config([
            'services.emi_admin.name' => 'Admin EMI',
            'services.emi_admin.email' => 'admin@emi.test',
            'services.emi_admin.password' => 'password-rahasia-testing',
        ]);

        $this->seed(AdminSeeder::class);

        $admin = User::query()->where('email', 'admin@emi.test')->firstOrFail();

        $this->assertSame('Admin EMI', $admin->full_name);
        $this->assertSame('admin', $admin->role);
        $this->assertSame('approved', $admin->status);
        $this->assertNotNull($admin->approved_at);
        $this->assertTrue(Hash::check('password-rahasia-testing', $admin->password));
    }

    public function test_user_email_must_be_unique(): void
    {
        User::factory()->create(['email' => 'duplikat@emi.test']);

        $this->expectException(QueryException::class);

        User::factory()->create(['email' => 'duplikat@emi.test']);
    }

    public function test_class_must_be_unique_per_school_name_and_academic_year(): void
    {
        $school = School::factory()->create();
        $admin = User::factory()->admin()->create();

        SchoolClass::factory()->create([
            'school_id' => $school->id,
            'created_by' => $admin->id,
            'name' => 'Kelas 7A',
            'academic_year' => '2026/2027',
        ]);

        $this->expectException(QueryException::class);

        SchoolClass::factory()->create([
            'school_id' => $school->id,
            'created_by' => $admin->id,
            'name' => 'Kelas 7A',
            'academic_year' => '2026/2027',
        ]);
    }

    public function test_teacher_cannot_have_two_active_assignments(): void
    {
        $teacher = User::factory()->teacher()->approved()->create();
        $admin = User::factory()->admin()->create();
        $firstClass = SchoolClass::factory()->create(['created_by' => $admin->id]);
        $secondClass = SchoolClass::factory()->create(['created_by' => $admin->id]);

        TeacherClassAssignment::factory()->create([
            'teacher_id' => $teacher->id,
            'class_id' => $firstClass->id,
            'assigned_by' => $admin->id,
        ]);

        $this->expectException(QueryException::class);

        TeacherClassAssignment::factory()->create([
            'teacher_id' => $teacher->id,
            'class_id' => $secondClass->id,
            'assigned_by' => $admin->id,
        ]);
    }

    public function test_class_cannot_have_two_active_teachers(): void
    {
        $firstTeacher = User::factory()->teacher()->approved()->create();
        $secondTeacher = User::factory()->teacher()->approved()->create();
        $admin = User::factory()->admin()->create();
        $schoolClass = SchoolClass::factory()->create(['created_by' => $admin->id]);

        TeacherClassAssignment::factory()->create([
            'teacher_id' => $firstTeacher->id,
            'class_id' => $schoolClass->id,
            'assigned_by' => $admin->id,
        ]);

        $this->expectException(QueryException::class);

        TeacherClassAssignment::factory()->create([
            'teacher_id' => $secondTeacher->id,
            'class_id' => $schoolClass->id,
            'assigned_by' => $admin->id,
        ]);
    }

    public function test_teacher_can_have_new_assignment_after_old_assignment_is_inactive(): void
    {
        $teacher = User::factory()->teacher()->approved()->create();
        $admin = User::factory()->admin()->create();
        $firstClass = SchoolClass::factory()->create(['created_by' => $admin->id]);
        $secondClass = SchoolClass::factory()->create(['created_by' => $admin->id]);

        $assignment = TeacherClassAssignment::factory()->create([
            'teacher_id' => $teacher->id,
            'class_id' => $firstClass->id,
            'assigned_by' => $admin->id,
        ]);

        $assignment->update([
            'is_active' => false,
            'ended_at' => now(),
        ]);

        $newAssignment = TeacherClassAssignment::factory()->create([
            'teacher_id' => $teacher->id,
            'class_id' => $secondClass->id,
            'assigned_by' => $admin->id,
        ]);

        $this->assertTrue($newAssignment->is_active);
    }

    public function test_student_cannot_have_two_active_memberships(): void
    {
        $student = User::factory()->student()->approved()->create();
        $admin = User::factory()->admin()->create();
        $firstClass = SchoolClass::factory()->create(['created_by' => $admin->id]);
        $secondClass = SchoolClass::factory()->create(['created_by' => $admin->id]);

        StudentClassMembership::factory()->create([
            'student_id' => $student->id,
            'class_id' => $firstClass->id,
            'assigned_by' => $admin->id,
        ]);

        $this->expectException(QueryException::class);

        StudentClassMembership::factory()->create([
            'student_id' => $student->id,
            'class_id' => $secondClass->id,
            'assigned_by' => $admin->id,
        ]);
    }

    public function test_student_can_have_new_membership_after_old_membership_is_inactive(): void
    {
        $student = User::factory()->student()->approved()->create();
        $admin = User::factory()->admin()->create();
        $firstClass = SchoolClass::factory()->create(['created_by' => $admin->id]);
        $secondClass = SchoolClass::factory()->create(['created_by' => $admin->id]);

        $membership = StudentClassMembership::factory()->create([
            'student_id' => $student->id,
            'class_id' => $firstClass->id,
            'assigned_by' => $admin->id,
        ]);

        $membership->update([
            'is_active' => false,
            'ended_at' => now(),
        ]);

        $newMembership = StudentClassMembership::factory()->create([
            'student_id' => $student->id,
            'class_id' => $secondClass->id,
            'assigned_by' => $admin->id,
        ]);

        $this->assertTrue($newMembership->is_active);
    }

    public function test_core_relationships_can_be_accessed(): void
    {
        $admin = User::factory()->admin()->create();
        $teacher = User::factory()->teacher()->approved()->create(['approved_by' => $admin->id]);
        $student = User::factory()->student()->approved()->create(['approved_by' => $admin->id]);
        $school = School::factory()->create(['created_by' => $admin->id]);
        $schoolClass = SchoolClass::factory()->create([
            'school_id' => $school->id,
            'created_by' => $admin->id,
        ]);

        $registrationRequest = RegistrationRequest::factory()->create([
            'user_id' => $student->id,
            'school_id' => $school->id,
            'class_id' => $schoolClass->id,
            'requested_role' => 'student',
            'status' => 'approved',
            'reviewed_by' => $admin->id,
            'reviewed_at' => now(),
        ]);

        $assignment = TeacherClassAssignment::factory()->create([
            'teacher_id' => $teacher->id,
            'class_id' => $schoolClass->id,
            'assigned_by' => $admin->id,
        ]);

        $membership = StudentClassMembership::factory()->create([
            'student_id' => $student->id,
            'class_id' => $schoolClass->id,
            'assigned_by' => $admin->id,
        ]);

        $this->assertTrue($teacher->approvedBy->is($admin));
        $this->assertTrue($admin->approvedUsers->contains($teacher));
        $this->assertTrue($admin->createdSchools->contains($school));
        $this->assertTrue($admin->createdClasses->contains($schoolClass));
        $this->assertTrue($student->registrationRequest->is($registrationRequest));
        $this->assertTrue($teacher->teacherClassAssignments->contains($assignment));
        $this->assertTrue($student->studentClassMemberships->contains($membership));
        $this->assertTrue($teacher->activeTeacherClassAssignment->is($assignment));
        $this->assertTrue($student->activeStudentClassMembership->is($membership));
        $this->assertTrue($school->creator->is($admin));
        $this->assertTrue($school->classes->contains($schoolClass));
        $this->assertTrue($school->registrationRequests->contains($registrationRequest));
        $this->assertTrue($schoolClass->school->is($school));
        $this->assertTrue($schoolClass->creator->is($admin));
        $this->assertTrue($schoolClass->registrationRequests->contains($registrationRequest));
        $this->assertTrue($schoolClass->teacherAssignments->contains($assignment));
        $this->assertTrue($schoolClass->studentMemberships->contains($membership));
        $this->assertTrue($schoolClass->activeTeacherAssignment->is($assignment));
        $this->assertTrue($schoolClass->activeStudentMemberships->contains($membership));
        $this->assertTrue($registrationRequest->user->is($student));
        $this->assertTrue($registrationRequest->school->is($school));
        $this->assertTrue($registrationRequest->schoolClass->is($schoolClass));
        $this->assertTrue($registrationRequest->reviewedBy->is($admin));
        $this->assertTrue($assignment->teacher->is($teacher));
        $this->assertTrue($assignment->schoolClass->is($schoolClass));
        $this->assertTrue($assignment->assignedBy->is($admin));
        $this->assertTrue($membership->student->is($student));
        $this->assertTrue($membership->schoolClass->is($schoolClass));
        $this->assertTrue($membership->assignedBy->is($admin));
    }

    public function test_invalid_role_and_status_are_rejected_by_database(): void
    {
        $this->expectException(QueryException::class);

        DB::table('users')->insert([
            'id' => (string) Str::uuid(),
            'full_name' => 'Role Invalid',
            'email' => 'invalid-role@emi.test',
            'password' => 'password',
            'role' => 'guardian',
            'status' => 'pending',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    public function test_invalid_status_is_rejected_by_database(): void
    {
        $this->expectException(QueryException::class);

        DB::table('users')->insert([
            'id' => (string) Str::uuid(),
            'full_name' => 'Status Invalid',
            'email' => 'invalid-status@emi.test',
            'password' => 'password',
            'role' => 'student',
            'status' => 'blocked',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}
