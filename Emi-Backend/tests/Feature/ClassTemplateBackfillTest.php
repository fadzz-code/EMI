<?php

namespace Tests\Feature;

use App\Models\ClassModule;
use App\Models\ClassQuiz;
use App\Models\ModuleTemplate;
use App\Models\QuizTemplate;
use App\Models\RegistrationRequest;
use App\Models\School;
use App\Models\SchoolClass;
use App\Models\StudentClassMembership;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ClassTemplateBackfillTest extends TestCase
{
    use RefreshDatabase;

    public function test_assignment_backfills_all_and_only_published_templates_as_drafts(): void
    {
        $admin = User::factory()->admin()->create();
        $teacher = User::factory()->teacher()->approved()->create();
        $class = SchoolClass::factory()->create();
        $publishedModule = ModuleTemplate::factory()->published()->create();
        $publishedQuiz = QuizTemplate::factory()->published()->create();
        $draftModule = ModuleTemplate::factory()->create();
        $draftQuiz = QuizTemplate::factory()->create();

        $this->assertDatabaseCount('class_modules', 0);
        $this->assertDatabaseCount('class_quizzes', 0);

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/classes/{$class->id}/assign-teacher", ['teacher_id' => $teacher->id])
            ->assertOk();

        $this->assertDatabaseHas('class_modules', ['class_id' => $class->id, 'source_module_template_id' => $publishedModule->id, 'status' => 'draft', 'created_by' => $teacher->id]);
        $this->assertDatabaseHas('class_quizzes', ['class_id' => $class->id, 'source_quiz_template_id' => $publishedQuiz->id, 'status' => 'draft', 'created_by' => $teacher->id]);
        $this->assertDatabaseMissing('class_modules', ['source_module_template_id' => $draftModule->id]);
        $this->assertDatabaseMissing('class_quizzes', ['source_quiz_template_id' => $draftQuiz->id]);
    }

    public function test_teacher_approval_backfills_after_user_becomes_approved(): void
    {
        $admin = User::factory()->admin()->create();
        $school = School::factory()->create();
        $class = SchoolClass::factory()->create(['school_id' => $school->id]);
        $teacher = User::factory()->teacher()->pending()->create();
        $module = ModuleTemplate::factory()->published()->create();
        $quiz = QuizTemplate::factory()->published()->create();
        $registration = RegistrationRequest::factory()->create([
            'user_id' => $teacher->id,
            'school_id' => $school->id,
            'class_id' => $class->id,
            'requested_role' => 'teacher',
            'status' => 'pending',
        ]);

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/admin/registration-requests/{$registration->id}/approve")
            ->assertOk();

        $this->assertDatabaseHas('users', ['id' => $teacher->id, 'status' => 'approved']);
        $this->assertDatabaseHas('class_modules', ['class_id' => $class->id, 'source_module_template_id' => $module->id, 'created_by' => $teacher->id]);
        $this->assertDatabaseHas('class_quizzes', ['class_id' => $class->id, 'source_quiz_template_id' => $quiz->id, 'created_by' => $teacher->id]);
    }

    public function test_reassignment_does_not_duplicate_or_overwrite_existing_copies(): void
    {
        $admin = User::factory()->admin()->create();
        $firstTeacher = User::factory()->teacher()->approved()->create();
        $secondTeacher = User::factory()->teacher()->approved()->create();
        $class = SchoolClass::factory()->create();
        ModuleTemplate::factory()->published()->create();
        QuizTemplate::factory()->published()->create();

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/classes/{$class->id}/assign-teacher", ['teacher_id' => $firstTeacher->id])->assertOk();
        ClassModule::query()->where('class_id', $class->id)->firstOrFail()->update(['title' => 'Modul Guru']);
        ClassQuiz::query()->where('class_id', $class->id)->firstOrFail()->update(['title' => 'Kuis Guru']);

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/classes/{$class->id}/assign-teacher", ['teacher_id' => $secondTeacher->id])->assertOk();

        $this->assertSame(1, ClassModule::query()->where('class_id', $class->id)->count());
        $this->assertSame(1, ClassQuiz::query()->where('class_id', $class->id)->count());
        $this->assertDatabaseHas('class_modules', ['class_id' => $class->id, 'title' => 'Modul Guru', 'created_by' => $firstTeacher->id]);
        $this->assertDatabaseHas('class_quizzes', ['class_id' => $class->id, 'title' => 'Kuis Guru', 'created_by' => $firstTeacher->id]);
    }

    public function test_student_cannot_see_backfilled_drafts(): void
    {
        $admin = User::factory()->admin()->create();
        $teacher = User::factory()->teacher()->approved()->create();
        $student = User::factory()->student()->approved()->create();
        $class = SchoolClass::factory()->create();
        ModuleTemplate::factory()->published()->create();
        QuizTemplate::factory()->published()->create();
        StudentClassMembership::factory()->create(['student_id' => $student->id, 'class_id' => $class->id]);

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/classes/{$class->id}/assign-teacher", ['teacher_id' => $teacher->id])->assertOk();

        $this->actingAs($student)->getJson('/api/v1/student/modules')->assertOk()->assertJsonCount(0, 'data');
        $this->actingAs($student)->getJson('/api/v1/student/quizzes')->assertOk()->assertJsonCount(0, 'data');
    }

    private function tokenFor(User $user): string
    {
        return $user->createToken('PHPUnit')->plainTextToken;
    }
}
