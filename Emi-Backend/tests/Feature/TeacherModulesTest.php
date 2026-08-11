<?php

namespace Tests\Feature;

use App\Models\ClassLesson;
use App\Models\ClassModule;
use App\Models\MediaFile;
use App\Models\ModuleProgress;
use App\Models\School;
use App\Models\SchoolClass;
use App\Models\StudentClassMembership;
use App\Models\TeacherClassAssignment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TeacherModulesTest extends TestCase
{
    use RefreshDatabase;

    public function test_teacher_module_access_follows_active_assignment_and_role_contract(): void
    {
        $admin = User::factory()->admin()->create();
        $school = School::factory()->create(['created_by' => $admin->id]);
        $ownClass = SchoolClass::factory()->create(['school_id' => $school->id, 'created_by' => $admin->id]);
        $oldClass = SchoolClass::factory()->create(['school_id' => $school->id, 'created_by' => $admin->id]);
        $foreignClass = SchoolClass::factory()->create(['school_id' => $school->id, 'created_by' => $admin->id]);
        $teacher = User::factory()->teacher()->approved()->create();
        $foreignTeacher = User::factory()->teacher()->approved()->create();
        $student = User::factory()->student()->approved()->create();
        TeacherClassAssignment::factory()->inactive()->create(['teacher_id' => $teacher->id, 'class_id' => $oldClass->id, 'assigned_by' => $admin->id]);
        TeacherClassAssignment::factory()->create(['teacher_id' => $teacher->id, 'class_id' => $ownClass->id, 'assigned_by' => $admin->id]);
        TeacherClassAssignment::factory()->create(['teacher_id' => $foreignTeacher->id, 'class_id' => $foreignClass->id, 'assigned_by' => $admin->id]);
        StudentClassMembership::factory()->create(['student_id' => $student->id, 'class_id' => $ownClass->id, 'assigned_by' => $admin->id]);
        $ownModule = ClassModule::factory()->create(['class_id' => $ownClass->id, 'created_by' => $teacher->id, 'title' => 'Modul Milik']);
        $this->getJson("/api/v1/class-modules/{$ownModule->id}")->assertUnauthorized();
        $this->putJson("/api/v1/class-modules/{$ownModule->id}", ['title' => 'Guest'])->assertUnauthorized();
        $oldModule = ClassModule::factory()->create(['class_id' => $oldClass->id, 'created_by' => $teacher->id]);
        $foreignModule = ClassModule::factory()->create(['class_id' => $foreignClass->id, 'created_by' => $foreignTeacher->id]);

        $this->withToken($this->tokenFor($teacher))->getJson("/api/v1/classes/{$ownClass->id}/modules")
            ->assertOk()->assertJsonPath('meta.total', 1)->assertJsonPath('data.0.id', $ownModule->id);
        $this->withToken($this->tokenFor($teacher))->getJson("/api/v1/class-modules/{$ownModule->id}")
            ->assertOk()->assertJsonPath('data.title', 'Modul Milik');
        $this->withToken($this->tokenFor($teacher))->putJson("/api/v1/class-modules/{$ownModule->id}", ['title' => 'Modul Diubah'])
            ->assertOk()->assertJsonPath('data.title', 'Modul Diubah');
        $this->withToken($this->tokenFor($teacher))->postJson("/api/v1/class-modules/{$ownModule->id}/publish")
            ->assertConflict()->assertJsonPath('code', 'MODULE_HAS_NO_PUBLISHED_LESSONS');

        foreach ([$oldModule, $foreignModule] as $module) {
            $this->withToken($this->tokenFor($teacher))->getJson("/api/v1/class-modules/{$module->id}")->assertForbidden();
            $this->withToken($this->tokenFor($teacher))->putJson("/api/v1/class-modules/{$module->id}", ['title' => 'Ditolak'])->assertForbidden();
            $this->withToken($this->tokenFor($teacher))->postJson("/api/v1/class-modules/{$module->id}/publish")->assertForbidden();
        }
        $this->withToken($this->tokenFor($teacher))->getJson("/api/v1/classes/{$oldClass->id}/modules")->assertForbidden();
        $this->withToken($this->tokenFor($foreignTeacher))->getJson("/api/v1/class-modules/{$ownModule->id}")->assertForbidden();
        $this->withToken($this->tokenFor($student))->getJson("/api/v1/class-modules/{$ownModule->id}")->assertForbidden();
        $this->withToken($this->tokenFor($student))->putJson("/api/v1/class-modules/{$ownModule->id}", ['title' => 'Siswa'])->assertForbidden();
        $this->withToken($this->tokenFor($admin))->getJson("/api/v1/class-modules/{$ownModule->id}")->assertOk();
        $this->withToken($this->tokenFor($admin))->putJson("/api/v1/class-modules/{$ownModule->id}", ['description' => 'Admin'])->assertOk();
    }

    public function test_teacher_can_edit_and_publish_own_lesson_without_losing_media_or_exposing_storage_fields(): void
    {
        $admin = User::factory()->admin()->create();
        $school = School::factory()->create(['created_by' => $admin->id]);
        $ownClass = SchoolClass::factory()->create(['school_id' => $school->id, 'created_by' => $admin->id]);
        $foreignClass = SchoolClass::factory()->create(['school_id' => $school->id, 'created_by' => $admin->id]);
        $teacher = User::factory()->teacher()->approved()->create();
        $foreignTeacher = User::factory()->teacher()->approved()->create();
        TeacherClassAssignment::factory()->create(['teacher_id' => $teacher->id, 'class_id' => $ownClass->id, 'assigned_by' => $admin->id]);
        TeacherClassAssignment::factory()->create(['teacher_id' => $foreignTeacher->id, 'class_id' => $foreignClass->id, 'assigned_by' => $admin->id]);
        $module = ClassModule::factory()->create(['class_id' => $ownClass->id, 'created_by' => $teacher->id]);
        $media = MediaFile::factory()->private()->create(['uploaded_by' => $teacher->id]);
        $lesson = ClassLesson::factory()->create([
            'class_module_id' => $module->id,
            'created_by' => $teacher->id,
            'content_type' => 'pdf',
            'media_id' => $media->id,
            'content_body' => null,
            'external_url' => null,
            'status' => 'draft',
        ]);

        $this->withToken($this->tokenFor($teacher))->getJson("/api/v1/class-modules/{$module->id}")
            ->assertOk()->assertJsonPath('data.lessons.0.media.id', $media->id)
            ->assertJsonMissingPath('data.lessons.0.media.path')->assertJsonMissingPath('data.lessons.0.media.checksum_sha256');
        $this->withToken($this->tokenFor($teacher))->putJson("/api/v1/class-lessons/{$lesson->id}", ['title' => 'Materi Diubah'])
            ->assertOk()->assertJsonPath('data.media.id', $media->id)
            ->assertJsonMissingPath('data.media.path')->assertJsonMissingPath('data.media.checksum_sha256');
        $this->assertDatabaseHas('class_lessons', ['id' => $lesson->id, 'media_id' => $media->id]);
        $this->withToken($this->tokenFor($teacher))->postJson("/api/v1/class-lessons/{$lesson->id}/publish")
            ->assertOk()->assertJsonPath('data.status', 'published')->assertJsonPath('data.media.id', $media->id)
            ->assertJsonMissingPath('data.media.path')->assertJsonMissingPath('data.media.checksum_sha256');
        $this->withToken($this->tokenFor($teacher))->postJson("/api/v1/class-modules/{$module->id}/publish")
            ->assertOk()->assertJsonPath('data.status', 'published');
        $this->withToken($this->tokenFor($foreignTeacher))->putJson("/api/v1/class-lessons/{$lesson->id}", ['title' => 'Ditolak'])->assertForbidden();
        $this->withToken($this->tokenFor($foreignTeacher))->postJson("/api/v1/class-lessons/{$lesson->id}/publish")->assertForbidden();
    }

    public function test_teacher_cannot_attach_another_teachers_private_media_to_lesson(): void
    {
        $admin = User::factory()->admin()->create();
        $school = School::factory()->create(['created_by' => $admin->id]);
        $class = SchoolClass::factory()->create(['school_id' => $school->id, 'created_by' => $admin->id]);
        $teacher = User::factory()->teacher()->approved()->create();
        $otherTeacher = User::factory()->teacher()->approved()->create();
        TeacherClassAssignment::factory()->create(['teacher_id' => $teacher->id, 'class_id' => $class->id, 'assigned_by' => $admin->id]);
        $module = ClassModule::factory()->create(['class_id' => $class->id, 'created_by' => $teacher->id]);
        $foreignMedia = MediaFile::factory()->private()->create(['uploaded_by' => $otherTeacher->id, 'purpose' => 'document', 'mime_type' => 'application/pdf']);

        $this->withToken($this->tokenFor($teacher))->postJson("/api/v1/class-modules/{$module->id}/lessons", [
            'title' => 'Media Asing',
            'content_type' => 'pdf',
            'media_id' => $foreignMedia->id,
        ])->assertUnprocessable()->assertJsonPath('code', 'INVALID_LESSON_MEDIA');
    }

    public function test_student_module_progress_only_contains_active_class(): void
    {
        $admin = User::factory()->admin()->create();
        $school = School::factory()->create(['created_by' => $admin->id]);
        $oldClass = SchoolClass::factory()->create(['school_id' => $school->id, 'created_by' => $admin->id]);
        $newClass = SchoolClass::factory()->create(['school_id' => $school->id, 'created_by' => $admin->id]);
        $student = User::factory()->student()->approved()->create();
        $oldMembership = StudentClassMembership::factory()->create(['student_id' => $student->id, 'class_id' => $oldClass->id, 'assigned_by' => $admin->id]);
        $oldModule = ClassModule::factory()->create(['class_id' => $oldClass->id, 'created_by' => $admin->id]);
        ModuleProgress::factory()->create(['student_id' => $student->id, 'class_module_id' => $oldModule->id]);
        $oldMembership->update(['is_active' => false]);
        StudentClassMembership::factory()->create(['student_id' => $student->id, 'class_id' => $newClass->id, 'assigned_by' => $admin->id]);

        $this->withToken($this->tokenFor($student))->getJson('/api/v1/student/progress/modules')
            ->assertOk()->assertJsonPath('meta.total', 0);
    }

    private function tokenFor(User $user): string
    {
        $this->app['auth']->forgetGuards();

        return $user->createToken('PHPUnit')->plainTextToken;
    }
}
