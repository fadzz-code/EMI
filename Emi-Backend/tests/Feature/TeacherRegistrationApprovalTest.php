<?php

namespace Tests\Feature;

use App\Models\RegistrationRequest;
use App\Models\School;
use App\Models\SchoolClass;
use App\Models\TeacherClassAssignment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TeacherRegistrationApprovalTest extends TestCase
{
    use RefreshDatabase;

    private User $teacher;

    private School $school;

    private SchoolClass $ownClass;

    private SchoolClass $otherClass;

    protected function setUp(): void
    {
        parent::setUp();

        $this->teacher = User::factory()->create(['role' => 'teacher']);
        $this->school = School::factory()->create();

        $this->ownClass = SchoolClass::factory()->create(['school_id' => $this->school->id]);
        $this->otherClass = SchoolClass::factory()->create(['school_id' => $this->school->id]);

        TeacherClassAssignment::create([
            'teacher_id' => $this->teacher->id,
            'class_id' => $this->ownClass->id,
            'is_active' => true,
            'assigned_by' => $this->teacher->id,
            'assigned_at' => now(),
        ]);
    }

    public function test_teacher_can_list_student_requests_in_own_class()
    {
        RegistrationRequest::factory()->create([
            'class_id' => $this->ownClass->id,
            'requested_role' => 'student',
        ]);

        $response = $this->actingAs($this->teacher)
            ->getJson('/api/v1/teacher/registration-requests');

        $response->assertStatus(200)
            ->assertJsonCount(1, 'data');
    }

    public function test_teacher_cannot_list_student_requests_in_other_class()
    {
        RegistrationRequest::factory()->create([
            'class_id' => $this->otherClass->id,
            'requested_role' => 'student',
        ]);

        $response = $this->actingAs($this->teacher)
            ->getJson('/api/v1/teacher/registration-requests');

        $response->assertStatus(200)
            ->assertJsonCount(0, 'data');
    }

    public function test_teacher_cannot_list_teacher_requests()
    {
        RegistrationRequest::factory()->create([
            'class_id' => $this->ownClass->id,
            'requested_role' => 'teacher',
        ]);

        $response = $this->actingAs($this->teacher)
            ->getJson('/api/v1/teacher/registration-requests');

        $response->assertStatus(200)
            ->assertJsonCount(0, 'data');
    }

    public function test_teacher_can_show_own_class_student_request()
    {
        $request = RegistrationRequest::factory()->create([
            'class_id' => $this->ownClass->id,
            'requested_role' => 'student',
        ]);

        $response = $this->actingAs($this->teacher)
            ->getJson('/api/v1/teacher/registration-requests/'.$request->id);

        $response->assertStatus(200)
            ->assertJsonPath('data.id', $request->id);
    }

    public function test_teacher_cannot_show_other_class_request()
    {
        $request = RegistrationRequest::factory()->create([
            'class_id' => $this->otherClass->id,
            'requested_role' => 'student',
        ]);

        $response = $this->actingAs($this->teacher)
            ->getJson('/api/v1/teacher/registration-requests/'.$request->id);

        $response->assertStatus(403);
    }

    public function test_teacher_can_approve_own_class_student_request()
    {
        $request = RegistrationRequest::factory()->create([
            'school_id' => $this->school->id,
            'class_id' => $this->ownClass->id,
            'requested_role' => 'student',
            'status' => 'pending',
        ]);

        $response = $this->actingAs($this->teacher)
            ->postJson('/api/v1/teacher/registration-requests/'.$request->id.'/approve', [
                'review_note' => 'OK',
            ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('registration_requests', [
            'id' => $request->id,
            'status' => 'approved',
            'reviewed_by' => $this->teacher->id,
        ]);

        $this->assertDatabaseHas('student_class_memberships', [
            'student_id' => $request->user_id,
            'class_id' => $this->ownClass->id,
            'is_active' => true,
        ]);
    }

    public function test_teacher_cannot_approve_teacher_request()
    {
        $request = RegistrationRequest::factory()->create([
            'class_id' => $this->ownClass->id,
            'requested_role' => 'teacher',
            'status' => 'pending',
        ]);

        $response = $this->actingAs($this->teacher)
            ->postJson('/api/v1/teacher/registration-requests/'.$request->id.'/approve');

        $response->assertStatus(403);
    }

    public function test_teacher_cannot_approve_other_class_student_request()
    {
        $request = RegistrationRequest::factory()->create([
            'class_id' => $this->otherClass->id,
            'requested_role' => 'student',
            'status' => 'pending',
        ]);

        $response = $this->actingAs($this->teacher)
            ->postJson('/api/v1/teacher/registration-requests/'.$request->id.'/approve');

        $response->assertStatus(403);
    }
}
