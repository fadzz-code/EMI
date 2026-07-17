<?php

namespace Tests\Feature;

use App\Models\ClassModule;
use App\Models\ModuleProgress;
use App\Models\School;
use App\Models\SchoolClass;
use App\Models\StudentClassMembership;
use App\Models\TeacherClassAssignment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TeacherDashboardClassesTest extends TestCase
{
    use RefreshDatabase;

    public function test_dashboard_uses_only_active_assignment_and_rejects_foreign_filters(): void
    {
        [$admin, $teacher, $class, $otherClass] = $this->dataset();
        $activeStudent = $this->student($class, $admin, 'Aktif');
        $inactiveStudent = $this->student($class, $admin, 'Tidak Aktif', false);
        $module = ClassModule::factory()->published()->create(['class_id' => $class->id, 'created_by' => $admin->id]);
        ModuleProgress::factory()->create(['student_id' => $activeStudent->id, 'class_module_id' => $module->id, 'status' => 'completed', 'progress_percent' => 100, 'completed_at' => now()]);
        ModuleProgress::factory()->create(['student_id' => $inactiveStudent->id, 'class_module_id' => $module->id, 'status' => 'completed', 'progress_percent' => 100, 'completed_at' => now()]);
        TeacherClassAssignment::factory()->inactive()->create(['teacher_id' => $teacher->id, 'class_id' => $otherClass->id, 'assigned_by' => $admin->id]);

        $response = $this->withToken($this->tokenFor($teacher))->getJson('/api/v1/teacher/dashboard/summary')
            ->assertOk()
            ->assertJsonPath('data.class.id', $class->id)
            ->assertJsonPath('data.students.active', 1)
            ->assertJsonPath('data.students.with_learning_activity', 1)
            ->assertJsonPath('data.learning.published_modules', 1)
            ->assertJsonCount(1, 'data.recent_activity');

        $this->assertSame('Aktif', $response->json('data.recent_activity.0.student_name'));
        $this->withToken($this->tokenFor($teacher))->getJson("/api/v1/teacher/dashboard/summary?class_id={$otherClass->id}")
            ->assertForbidden()->assertJsonPath('code', 'REPORT_SCOPE_FORBIDDEN');
        $this->withToken($this->tokenFor($teacher))->getJson("/api/v1/teacher/dashboard/summary?school_id={$otherClass->school_id}")
            ->assertForbidden()->assertJsonPath('code', 'REPORT_SCOPE_FORBIDDEN');
    }

    public function test_teacher_classes_only_expose_own_active_class_and_active_students(): void
    {
        [$admin, $teacher, $class, $otherClass] = $this->dataset();
        $activeStudent = $this->student($class, $admin, 'Aktif');
        $this->student($class, $admin, 'Tidak Aktif', false);
        $this->student($otherClass, $admin, 'Kelas Lain');
        $token = $this->tokenFor($teacher);

        $this->withToken($token)->getJson('/api/v1/classes')->assertOk()
            ->assertJsonCount(1, 'data')->assertJsonPath('data.0.id', $class->id)
            ->assertJsonPath('data.0.active_students_count', 1);
        $this->withToken($token)->getJson("/api/v1/classes/{$class->id}")->assertOk()
            ->assertJsonPath('data.id', $class->id)->assertJsonPath('data.active_students_count', 1);
        $this->withToken($token)->getJson("/api/v1/classes/{$otherClass->id}")->assertForbidden();

        $students = $this->withToken($token)->getJson("/api/v1/classes/{$class->id}/students")
            ->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.student.id', $activeStudent->id)
            ->assertJsonPath('data.0.student.email', $activeStudent->email);
        foreach (['password', 'remember_token', 'phone'] as $field) {
            $this->assertStringNotContainsString($field, $students->getContent());
        }
    }

    public function test_admin_student_and_guest_authorization_contracts(): void
    {
        [$admin, $teacher, $class] = $this->dataset();
        $student = $this->student($class, $admin, 'Siswa');

        $this->withToken($this->tokenFor($admin))->getJson("/api/v1/classes/{$class->id}/students")->assertOk();
        $this->withToken($this->tokenFor($student))->getJson("/api/v1/classes/{$class->id}")->assertOk();
        $this->withToken($this->tokenFor($student))->getJson("/api/v1/classes/{$class->id}/students")->assertForbidden();
        $this->withToken($this->tokenFor($student))->getJson('/api/v1/teacher/dashboard/summary')->assertForbidden();
        $this->withToken($this->tokenFor($teacher))->getJson("/api/v1/classes/{$class->id}/students")->assertOk();
    }

    public function test_guest_cannot_access_dashboard_or_classes(): void
    {
        $this->getJson('/api/v1/classes')->assertUnauthorized();
        $this->getJson('/api/v1/teacher/dashboard/summary')->assertUnauthorized();
    }

    private function dataset(): array
    {
        $admin = User::factory()->admin()->create();
        $school = School::factory()->create(['created_by' => $admin->id]);
        $otherSchool = School::factory()->create(['created_by' => $admin->id]);
        $class = SchoolClass::factory()->create(['school_id' => $school->id, 'created_by' => $admin->id]);
        $otherClass = SchoolClass::factory()->create(['school_id' => $otherSchool->id, 'created_by' => $admin->id]);
        $teacher = User::factory()->teacher()->approved()->create();
        TeacherClassAssignment::factory()->create(['teacher_id' => $teacher->id, 'class_id' => $class->id, 'assigned_by' => $admin->id]);

        return [$admin, $teacher, $class, $otherClass];
    }

    private function student(SchoolClass $class, User $admin, string $name, bool $active = true): User
    {
        $student = User::factory()->student()->approved()->create(['full_name' => $name]);
        StudentClassMembership::factory()->state(['is_active' => $active])->create(['student_id' => $student->id, 'class_id' => $class->id, 'assigned_by' => $admin->id]);

        return $student;
    }

    private function tokenFor(User $user): string
    {
        $this->app['auth']->forgetGuards();

        return $user->createToken('PHPUnit')->plainTextToken;
    }
}
