<?php

namespace Tests\Feature;

use App\Models\School;
use App\Models\SchoolClass;
use App\Models\StudentClassMembership;
use App\Models\TeacherClassAssignment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class Phase3SchoolClassUsersTest extends TestCase
{
    use RefreshDatabase;

    public function test_school_endpoints_require_login_and_admin_can_manage_school_with_audit(): void
    {
        $this->getJson('/api/v1/schools')->assertUnauthorized();

        $admin = User::factory()->admin()->create();
        $otherAdmin = User::factory()->admin()->create();

        $response = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/schools', [
            'name' => 'SMP Negeri 1 Kolaka',
            'address' => 'Kolaka',
            'phone' => '0405',
            'status' => 'active',
            'created_by' => $otherAdmin->id,
        ]);

        $response->assertCreated()->assertJsonPath('data.created_by', $admin->id);
        $schoolId = $response->json('data.id');

        $this->withToken($this->tokenFor($admin))->putJson("/api/v1/schools/{$schoolId}", [
            'name' => 'SMP Negeri 1 Kolaka Baru',
            'address' => 'Kolaka',
            'phone' => '0406',
            'status' => 'active',
            'created_by' => $otherAdmin->id,
        ])->assertOk()->assertJsonPath('data.created_by', $admin->id);

        $this->assertDatabaseHas('audit_logs', ['action' => 'school.created']);
        $this->assertDatabaseHas('audit_logs', ['action' => 'school.updated']);
    }

    public function test_teacher_and_student_only_see_their_own_school_and_idor_is_forbidden(): void
    {
        [$teacher, $student, $school, $class] = $this->assignedTeacherAndStudent();
        $otherSchool = School::factory()->create();

        $this->withToken($this->tokenFor($teacher))->getJson('/api/v1/schools')
            ->assertOk()
            ->assertJsonPath('data.0.id', $school->id);

        $this->withToken($this->tokenFor($student))->getJson('/api/v1/schools')
            ->assertOk()
            ->assertJsonPath('data.0.id', $school->id);

        $this->withToken($this->tokenFor($teacher))->getJson("/api/v1/schools/{$otherSchool->id}")->assertForbidden();
        $this->withToken($this->tokenFor($student))->getJson("/api/v1/schools/{$otherSchool->id}")->assertForbidden();
        $this->withToken($this->tokenFor($teacher))->postJson('/api/v1/schools', ['name' => 'Dilarang'])->assertForbidden();

        $this->assertSame($class->school_id, $school->id);
    }

    public function test_school_deactivation_rejects_active_classes_and_keeps_record(): void
    {
        $admin = User::factory()->admin()->create();
        $school = School::factory()->create();
        SchoolClass::factory()->create(['school_id' => $school->id, 'status' => 'active']);

        $this->withToken($this->tokenFor($admin))->deleteJson("/api/v1/schools/{$school->id}")
            ->assertConflict()
            ->assertJsonPath('code', 'SCHOOL_HAS_ACTIVE_CLASSES');

        SchoolClass::query()->where('school_id', $school->id)->update(['status' => 'inactive']);

        $this->withToken($this->tokenFor($admin))->deleteJson("/api/v1/schools/{$school->id}")
            ->assertOk()
            ->assertJsonPath('data.status', 'inactive');

        $this->assertDatabaseHas('schools', ['id' => $school->id, 'status' => 'inactive']);
        $this->assertDatabaseHas('audit_logs', ['action' => 'school.deactivated']);

        $this->withToken($this->tokenFor($admin))->putJson("/api/v1/schools/{$school->id}", [
            'name' => $school->name,
            'address' => $school->address,
            'phone' => $school->phone,
            'status' => 'active',
        ])->assertOk()->assertJsonPath('data.status', 'active');

        $this->assertDatabaseHas('audit_logs', ['action' => 'school.reactivated']);
    }

    public function test_class_scope_crud_deactivation_duplicate_and_audit(): void
    {
        $admin = User::factory()->admin()->create();
        [$teacher, $student, $school, $class] = $this->assignedTeacherAndStudent();
        $otherClass = SchoolClass::factory()->create();

        $this->withToken($this->tokenFor($admin))->getJson('/api/v1/classes')->assertOk();
        $this->withToken($this->tokenFor($teacher))->getJson('/api/v1/classes')
            ->assertOk()
            ->assertJsonPath('data.0.id', $class->id);
        $this->withToken($this->tokenFor($student))->getJson('/api/v1/classes')
            ->assertOk()
            ->assertJsonPath('data.0.id', $class->id);
        $this->withToken($this->tokenFor($teacher))->getJson("/api/v1/classes/{$otherClass->id}")->assertForbidden();
        $this->withToken($this->tokenFor($student))->getJson("/api/v1/classes/{$otherClass->id}")->assertForbidden();

        $created = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/classes', [
            'school_id' => $school->id,
            'name' => 'Kelas 8A',
            'grade_level' => '8',
            'academic_year' => '2026/2027',
            'status' => 'active',
        ])->assertCreated()->json('data');

        $this->withToken($this->tokenFor($admin))->postJson('/api/v1/classes', [
            'school_id' => $school->id,
            'name' => 'Kelas 8A',
            'grade_level' => '8',
            'academic_year' => '2026/2027',
            'status' => 'active',
        ])->assertConflict()->assertJsonPath('code', 'CLASS_DUPLICATE');

        $inactiveSchool = School::factory()->inactive()->create();
        $this->withToken($this->tokenFor($admin))->postJson('/api/v1/classes', [
            'school_id' => $inactiveSchool->id,
            'name' => 'Kelas X',
            'academic_year' => '2026/2027',
            'status' => 'active',
        ])->assertConflict()->assertJsonPath('code', 'SCHOOL_INACTIVE');

        $this->withToken($this->tokenFor($admin))->putJson("/api/v1/classes/{$created['id']}", [
            'school_id' => $inactiveSchool->id,
            'name' => 'Kelas 8B',
            'grade_level' => '8',
            'academic_year' => '2026/2027',
            'status' => 'active',
        ])->assertOk()->assertJsonPath('data.school_id', $school->id);

        $this->withToken($this->tokenFor($admin))->deleteJson("/api/v1/classes/{$class->id}")
            ->assertConflict()
            ->assertJsonPath('code', 'CLASS_HAS_ACTIVE_TEACHER');

        $emptyClass = SchoolClass::factory()->create(['school_id' => $school->id]);
        $this->withToken($this->tokenFor($admin))->deleteJson("/api/v1/classes/{$emptyClass->id}")
            ->assertOk()
            ->assertJsonPath('data.status', 'inactive');
        $this->assertDatabaseHas('classes', ['id' => $emptyClass->id, 'status' => 'inactive']);
        $this->assertDatabaseHas('audit_logs', ['action' => 'class.created']);
        $this->assertDatabaseHas('audit_logs', ['action' => 'class.updated']);
        $this->assertDatabaseHas('audit_logs', ['action' => 'class.deactivated']);
    }

    public function test_teacher_assignment_reassignment_history_and_audit(): void
    {
        $admin = User::factory()->admin()->create();
        $teacher = User::factory()->teacher()->approved()->create();
        $newTeacher = User::factory()->teacher()->approved()->create();
        $class = SchoolClass::factory()->create();
        $otherClass = SchoolClass::factory()->create();

        $this->withToken($this->tokenFor(User::factory()->teacher()->approved()->create()))
            ->postJson("/api/v1/classes/{$class->id}/assign-teacher", ['teacher_id' => $teacher->id])
            ->assertForbidden();

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/classes/{$class->id}/assign-teacher", ['teacher_id' => User::factory()->student()->approved()->create()->id])
            ->assertUnprocessable()
            ->assertJsonPath('code', 'INVALID_USER_ROLE');

        foreach (['pending', 'rejected', 'inactive'] as $status) {
            $this->withToken($this->tokenFor($admin))
                ->postJson("/api/v1/classes/{$class->id}/assign-teacher", ['teacher_id' => User::factory()->teacher()->state(['status' => $status])->create()->id])
                ->assertUnprocessable()
                ->assertJsonPath('code', 'USER_NOT_APPROVED');
        }

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/classes/{$class->id}/assign-teacher", ['teacher_id' => $teacher->id])
            ->assertOk();
        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/classes/{$class->id}/assign-teacher", ['teacher_id' => $teacher->id])
            ->assertOk();
        $this->assertSame(1, TeacherClassAssignment::query()->where('teacher_id', $teacher->id)->count());

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/classes/{$otherClass->id}/assign-teacher", ['teacher_id' => $teacher->id])
            ->assertOk();
        $this->assertSame(1, TeacherClassAssignment::query()->where('teacher_id', $teacher->id)->where('is_active', true)->count());

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/classes/{$otherClass->id}/assign-teacher", ['teacher_id' => $newTeacher->id])
            ->assertOk();
        $this->assertSame(1, TeacherClassAssignment::query()->where('class_id', $otherClass->id)->where('is_active', true)->count());
        $this->assertGreaterThan(1, TeacherClassAssignment::query()->where('class_id', $otherClass->id)->count());
        $this->assertDatabaseHas('audit_logs', ['action' => 'class.teacher_assigned']);
        $this->assertDatabaseHas('audit_logs', ['action' => 'class.teacher_reassigned']);
    }

    public function test_student_assignment_move_history_and_audit(): void
    {
        $admin = User::factory()->admin()->create();
        $student = User::factory()->student()->approved()->create();
        $class = SchoolClass::factory()->create();
        $otherClass = SchoolClass::factory()->create();

        $this->withToken($this->tokenFor(User::factory()->teacher()->approved()->create()))
            ->postJson("/api/v1/classes/{$class->id}/assign-student", ['student_id' => $student->id])
            ->assertForbidden();

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/classes/{$class->id}/assign-student", ['student_id' => User::factory()->teacher()->approved()->create()->id])
            ->assertUnprocessable()
            ->assertJsonPath('code', 'INVALID_USER_ROLE');

        foreach (['pending', 'rejected', 'inactive'] as $status) {
            $this->withToken($this->tokenFor($admin))
                ->postJson("/api/v1/classes/{$class->id}/assign-student", ['student_id' => User::factory()->student()->state(['status' => $status])->create()->id])
                ->assertUnprocessable()
                ->assertJsonPath('code', 'USER_NOT_APPROVED');
        }

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/classes/{$class->id}/assign-student", ['student_id' => $student->id])
            ->assertOk();
        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/classes/{$class->id}/assign-student", ['student_id' => $student->id])
            ->assertOk();
        $this->assertSame(1, StudentClassMembership::query()->where('student_id', $student->id)->count());

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/classes/{$otherClass->id}/assign-student", ['student_id' => $student->id])
            ->assertOk();
        $this->assertSame(1, StudentClassMembership::query()->where('student_id', $student->id)->where('is_active', true)->count());
        $this->assertGreaterThan(1, StudentClassMembership::query()->where('student_id', $student->id)->count());
        $this->assertDatabaseHas('audit_logs', ['action' => 'class.student_assigned']);
        $this->assertDatabaseHas('audit_logs', ['action' => 'class.student_moved']);
    }

    public function test_class_students_endpoint_scope_search_pagination_and_no_sensitive_data(): void
    {
        [$teacher, $student, $school, $class] = $this->assignedTeacherAndStudent(['full_name' => 'Siswa Dicari']);
        $otherClass = SchoolClass::factory()->create();
        $otherStudent = User::factory()->student()->approved()->create();
        StudentClassMembership::factory()->create(['student_id' => $otherStudent->id, 'class_id' => $otherClass->id]);

        $admin = User::factory()->admin()->create();

        $this->withToken($this->tokenFor($admin))->getJson("/api/v1/classes/{$class->id}/students?search=Dicari&per_page=1")
            ->assertOk()
            ->assertJsonPath('meta.per_page', 1)
            ->assertJsonPath('data.0.student.id', $student->id)
            ->assertJsonMissingPath('data.0.student.password');

        $this->withToken($this->tokenFor($teacher))->getJson("/api/v1/classes/{$class->id}/students")->assertOk();
        $this->withToken($this->tokenFor($teacher))->getJson("/api/v1/classes/{$otherClass->id}/students")->assertForbidden();
        $this->withToken($this->tokenFor($student))->getJson("/api/v1/classes/{$class->id}/students")->assertForbidden();
    }

    public function test_user_management_scope_filters_update_and_audit(): void
    {
        $this->getJson('/api/v1/users')->assertUnauthorized();

        [$teacher, $student, $school, $class] = $this->assignedTeacherAndStudent(['full_name' => 'Budi Siswa', 'email' => 'budi@example.test']);
        $otherStudent = User::factory()->student()->approved()->create(['full_name' => 'Siswa Lain']);
        StudentClassMembership::factory()->create(['student_id' => $otherStudent->id, 'class_id' => SchoolClass::factory()->create()->id]);
        $admin = User::factory()->admin()->create();

        $userList = $this->withToken($this->tokenFor($admin))->getJson('/api/v1/users?role=student&status=approved&search=Budi')
            ->assertOk()
            ->assertJsonMissingPath('data.0.password')
            ->assertJsonMissingPath('data.0.remember_token')
            ->assertJsonMissingPath('data.0.tokens');
        $this->assertContains($student->id, collect($userList->json('data'))->pluck('id')->all());
        $schoolUsers = $this->withToken($this->tokenFor($admin))->getJson("/api/v1/users?school_id={$school->id}")->assertOk();
        $this->assertContains($teacher->id, collect($schoolUsers->json('data'))->pluck('id')->all());
        $classUsers = $this->withToken($this->tokenFor($admin))->getJson("/api/v1/users?class_id={$class->id}")->assertOk();
        $this->assertContains($student->id, collect($classUsers->json('data'))->pluck('id')->all());

        $teacherList = $this->withToken($this->tokenFor($teacher))->getJson('/api/v1/users')->assertOk();
        $this->assertSame([$student->id], collect($teacherList->json('data'))->pluck('id')->all());
        $this->withToken($this->tokenFor($teacher))->getJson("/api/v1/users/{$student->id}")->assertOk();
        $this->withToken($this->tokenFor($teacher))->getJson("/api/v1/users/{$otherStudent->id}")->assertForbidden();
        $this->withToken($this->tokenFor($student))->getJson('/api/v1/users')->assertForbidden();

        $this->withToken($this->tokenFor($admin))->putJson("/api/v1/users/{$student->id}", [
            'full_name' => 'Budi Baru',
            'email' => 'BUDI.BARU@example.test',
            'phone' => '0812',
            'role' => 'admin',
            'status' => 'inactive',
            'password' => 'PasswordBaru123',
        ])->assertOk()->assertJsonPath('data.email', 'budi.baru@example.test');

        $student->refresh();
        $this->assertSame('student', $student->role);
        $this->assertSame('approved', $student->status);
        $this->assertFalse(Hash::check('PasswordBaru123', $student->password));
        $this->assertDatabaseHas('audit_logs', ['action' => 'user.updated']);
    }

    public function test_user_status_deactivation_reactivation_token_revoke_and_admin_safety(): void
    {
        $admin = User::factory()->admin()->create();
        $otherAdmin = User::factory()->admin()->create();
        [$teacher, $student] = [User::factory()->teacher()->approved()->create(), User::factory()->student()->approved()->create()];
        $class = SchoolClass::factory()->create();
        TeacherClassAssignment::factory()->create(['teacher_id' => $teacher->id, 'class_id' => $class->id]);
        StudentClassMembership::factory()->create(['student_id' => $student->id, 'class_id' => $class->id]);
        $studentToken = $this->tokenFor($student);

        $this->withToken($this->tokenFor($admin))->patchJson("/api/v1/users/{$teacher->id}/status", [
            'status' => 'inactive',
            'reason' => 'Nonaktif',
        ])->assertOk();
        $this->assertDatabaseHas('teacher_class_assignments', ['teacher_id' => $teacher->id, 'is_active' => false]);

        $this->withToken($this->tokenFor($admin))->patchJson("/api/v1/users/{$student->id}/status", [
            'status' => 'inactive',
            'reason' => 'Nonaktif',
        ])->assertOk();
        $this->assertDatabaseHas('student_class_memberships', ['student_id' => $student->id, 'is_active' => false]);
        $this->app['auth']->forgetGuards();
        $this->withToken($studentToken)->getJson('/api/v1/auth/me')->assertUnauthorized();

        $this->withToken($this->tokenFor($admin))->patchJson("/api/v1/users/{$student->id}/status", [
            'status' => 'approved',
        ])->assertOk();
        $this->assertDatabaseMissing('student_class_memberships', ['student_id' => $student->id, 'is_active' => true]);

        $pending = User::factory()->student()->pending()->create();
        $rejected = User::factory()->student()->rejected()->create();
        $this->withToken($this->tokenFor($admin))->patchJson("/api/v1/users/{$pending->id}/status", ['status' => 'approved'])->assertConflict();
        $this->withToken($this->tokenFor($admin))->patchJson("/api/v1/users/{$rejected->id}/status", ['status' => 'approved'])->assertConflict();
        $this->withToken($this->tokenFor($admin))->patchJson("/api/v1/users/{$admin->id}/status", ['status' => 'inactive', 'reason' => 'No'])->assertConflict();
        $otherAdmin->forceFill(['status' => 'inactive'])->save();
        $this->withToken($this->tokenFor($admin))->patchJson("/api/v1/users/{$otherAdmin->id}/status", ['status' => 'inactive', 'reason' => 'No'])->assertOk();

        $this->assertDatabaseHas('audit_logs', ['action' => 'user.deactivated']);
        $this->assertDatabaseHas('audit_logs', ['action' => 'user.reactivated']);
    }

    public function test_error_and_pagination_shapes_are_standard(): void
    {
        $admin = User::factory()->admin()->create();

        $this->withToken($this->tokenFor($admin))->postJson('/api/v1/schools', [])
            ->assertUnprocessable()
            ->assertJsonStructure(['success', 'message', 'code', 'errors'])
            ->assertJsonPath('code', 'VALIDATION_ERROR');

        School::factory()->count(2)->create();
        $this->withToken($this->tokenFor($admin))->getJson('/api/v1/schools?per_page=1')
            ->assertOk()
            ->assertJsonStructure(['success', 'message', 'data', 'meta' => ['current_page', 'per_page', 'total', 'last_page']]);
    }

    private function assignedTeacherAndStudent(array $studentOverrides = []): array
    {
        $teacher = User::factory()->teacher()->approved()->create();
        $student = User::factory()->student()->approved()->create($studentOverrides);
        $school = School::factory()->create();
        $class = SchoolClass::factory()->create(['school_id' => $school->id]);
        TeacherClassAssignment::factory()->create(['teacher_id' => $teacher->id, 'class_id' => $class->id]);
        StudentClassMembership::factory()->create(['student_id' => $student->id, 'class_id' => $class->id]);

        return [$teacher, $student, $school, $class];
    }

    private function tokenFor(User $user): string
    {
        $this->app['auth']->forgetGuards();

        return $user->createToken('PHPUnit')->plainTextToken;
    }
}
