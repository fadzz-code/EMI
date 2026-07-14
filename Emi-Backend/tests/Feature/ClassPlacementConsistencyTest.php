<?php

namespace Tests\Feature;

use App\Models\School;
use App\Models\SchoolClass;
use App\Models\StudentClassMembership;
use App\Models\TeacherClassAssignment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ClassPlacementConsistencyTest extends TestCase
{
    use RefreshDatabase;

    public function test_assign_teacher_and_student_moves_them_safely_across_classes_and_closes_old_records(): void
    {
        $admin = User::factory()->admin()->create();
        Sanctum::actingAs($admin, ['*']);
        
        $school = School::factory()->create();
        $class1 = SchoolClass::factory()->create(['school_id' => $school->id]);
        $teacher = User::factory()->teacher()->approved()->create();
        $student = User::factory()->student()->approved()->create();
        
        TeacherClassAssignment::factory()->create(['teacher_id' => $teacher->id, 'class_id' => $class1->id, 'is_active' => true]);
        StudentClassMembership::factory()->create(['student_id' => $student->id, 'class_id' => $class1->id, 'is_active' => true]);

        $class2 = SchoolClass::factory()->create(['school_id' => $school->id]);

        $this->getJson("/api/v1/classes/{$class1->id}")
            ->assertOk()
            ->assertJsonPath('data.active_teacher_assignment.teacher.id', $teacher->id)
            ->assertJsonPath('data.active_students_count', 1);

        $this->postJson("/api/v1/classes/{$class2->id}/assign-teacher", ['teacher_id' => $teacher->id])
            ->assertOk();

        $this->postJson("/api/v1/classes/{$class2->id}/assign-student", ['student_id' => $student->id])
            ->assertOk();

        $this->assertDatabaseHas('teacher_class_assignments', ['teacher_id' => $teacher->id, 'class_id' => $class1->id, 'is_active' => false]);
        $this->assertDatabaseHas('teacher_class_assignments', ['teacher_id' => $teacher->id, 'class_id' => $class2->id, 'is_active' => true]);
        $this->assertSame(1, TeacherClassAssignment::query()->where('teacher_id', $teacher->id)->where('is_active', true)->count());

        $this->assertDatabaseHas('student_class_memberships', ['student_id' => $student->id, 'class_id' => $class1->id, 'is_active' => false]);
        $this->assertDatabaseHas('student_class_memberships', ['student_id' => $student->id, 'class_id' => $class2->id, 'is_active' => true]);
        $this->assertSame(1, StudentClassMembership::query()->where('student_id', $student->id)->where('is_active', true)->count());

        $this->getJson("/api/v1/classes/{$class1->id}")
            ->assertOk()
            ->assertJsonPath('data.active_teacher_assignment', null)
            ->assertJsonPath('data.active_students_count', 0);
        
        $this->getJson("/api/v1/classes/{$class1->id}/students")
            ->assertOk()
            ->assertJsonCount(0, 'data');

        $this->getJson("/api/v1/classes/{$class2->id}")
            ->assertOk()
            ->assertJsonPath('data.active_teacher_assignment.teacher.id', $teacher->id)
            ->assertJsonPath('data.active_students_count', 1);

        $this->getJson("/api/v1/classes/{$class2->id}/students")
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.student.id', $student->id);
            
        // Test deactivate
        $this->deleteJson("/api/v1/classes/{$class2->id}")
            ->assertConflict()
            ->assertJsonPath('code', 'CLASS_HAS_ACTIVE_TEACHER');
            
        $this->deleteJson("/api/v1/classes/{$class1->id}")
            ->assertOk()
            ->assertJsonPath('data.status', 'inactive');
            
        $this->postJson("/api/v1/classes/{$class1->id}/assign-teacher", ['teacher_id' => $teacher->id])
            ->assertConflict();
    }
}
