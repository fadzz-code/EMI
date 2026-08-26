<?php

namespace Tests\Feature;

use App\Models\ClassLesson;
use App\Models\ClassModule;
use App\Models\LessonProgress;
use App\Models\LessonTemplate;
use App\Models\MediaFile;
use App\Models\ModuleProgress;
use App\Models\ModuleTemplate;
use App\Models\School;
use App\Models\SchoolClass;
use App\Models\StudentClassMembership;
use App\Models\TeacherClassAssignment;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class Phase6ModulesLessonsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('local');
        Storage::fake('public');
        config([
            'media.public_disk' => 'public',
            'media.private_disk' => 'local',
        ]);
    }

    public function test_schema_constraints_and_relationships(): void
    {
        $admin = User::factory()->admin()->create();
        $module = ModuleTemplate::factory()->create(['created_by' => $admin->id]);
        $lesson = LessonTemplate::factory()->create(['module_template_id' => $module->id, 'created_by' => $admin->id]);
        $classModule = ClassModule::factory()->create(['created_by' => $admin->id]);
        $classLesson = ClassLesson::factory()->create(['class_module_id' => $classModule->id, 'created_by' => $admin->id]);
        $student = User::factory()->student()->approved()->create();

        $this->assertSame($module->id, $lesson->moduleTemplate->id);
        $this->assertSame($classModule->id, $classLesson->classModule->id);
        LessonProgress::factory()->create(['student_id' => $student->id, 'class_lesson_id' => $classLesson->id]);
        $this->expectException(QueryException::class);
        LessonProgress::factory()->create(['student_id' => $student->id, 'class_lesson_id' => $classLesson->id]);
    }

    public function test_database_rejects_invalid_module_values(): void
    {
        $admin = User::factory()->admin()->create();

        $this->expectException(QueryException::class);
        ModuleTemplate::query()->create([
            'title' => 'Rusak',
            'status' => 'invalid',
            'created_by' => $admin->id,
        ]);
    }

    public function test_admin_template_and_lesson_crud_publish_reorder_media_validation_and_audit(): void
    {
        $admin = User::factory()->admin()->create();
        $teacher = User::factory()->teacher()->approved()->create();
        $image = $this->media($admin, 'lesson_image', $this->pngFile(), 'public');
        $audio = $this->media($admin, 'audio', $this->mp3File(), 'private');
        $pdf = $this->media($admin, 'document', $this->pdfFile(), 'private');
        $wrong = $this->media($admin, 'question_image', $this->pngFile('question.png'), 'public');

        $this->withToken($this->tokenFor($teacher))->postJson('/api/v1/admin/module-templates', ['title' => 'Dasar'])
            ->assertForbidden();

        $this->withToken($this->tokenFor($admin))->post('/api/v1/media', [
            'file' => UploadedFile::fake()->create('bad.txt', 1, 'text/plain'),
            'purpose' => 'lesson_image',
            'visibility' => 'public',
        ])->assertUnprocessable();

        $this->withToken($this->tokenFor($admin))->post('/api/v1/media', [
            'file' => UploadedFile::fake()->create('big.png', 5121, 'image/png'),
            'purpose' => 'lesson_image',
            'visibility' => 'public',
        ])->assertUnprocessable();

        $templateId = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/module-templates', [
            'title' => 'Kosakata Dasar',
            'description' => 'Modul global',
        ])->assertCreated()->json('data.id');

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/module-templates/{$templateId}/publish")
            ->assertConflict()
            ->assertJsonPath('code', 'MODULE_HAS_NO_PUBLISHED_LESSONS');

        $textLessonId = $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/module-templates/{$templateId}/lessons", [
            'title' => 'Text',
            'content_type' => 'text',
            'content_body' => 'Materi aman',
            'status' => 'published',
        ])->assertCreated()->json('data.id');

        $imageLessonId = null;
        foreach ([
            ['Image', 'image', $image->id, null],
            ['Audio', 'audio', $audio->id, null],
            ['PDF', 'pdf', $pdf->id, null],
            ['Video', 'video', null, 'https://example.com/video'],
            ['Link', 'link', null, 'https://example.com/link'],
        ] as [$title, $type, $mediaId, $url]) {
            $payload = ['title' => $title, 'content_type' => $type, 'status' => 'published'];
            $payload['media_id'] = $mediaId;
            $payload['external_url'] = $url;
            $createdId = $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/module-templates/{$templateId}/lessons", $payload)
                ->assertCreated()
                ->assertJsonMissingPath('data.media.path')
                ->json('data.id');
            if ($type === 'image') {
                $imageLessonId = $createdId;
            }
        }

        $this->withToken($this->tokenFor($admin))->putJson("/api/v1/admin/lesson-templates/{$imageLessonId}", [
            'title' => 'Image Renamed',
        ])->assertOk()->assertJsonPath('data.media.id', $image->id);

        $replacement = $this->media($admin, 'lesson_image', $this->pngFile('replacement.png'), 'public');
        $this->withToken($this->tokenFor($admin))->putJson("/api/v1/admin/lesson-templates/{$imageLessonId}", [
            'media_id' => $replacement->id,
        ])->assertOk()->assertJsonPath('data.media.id', $replacement->id);
        $this->assertDatabaseHas('media_files', ['id' => $image->id]);

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/module-templates/{$templateId}/lessons", [
            'title' => 'Salah',
            'content_type' => 'image',
            'media_id' => $wrong->id,
        ])->assertUnprocessable()->assertJsonPath('code', 'INVALID_LESSON_MEDIA');

        $deletedMedia = MediaFile::factory()->lessonImage()->create(['uploaded_by' => $admin->id]);
        $deletedMedia->delete();
        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/module-templates/{$templateId}/lessons", [
            'title' => 'Deleted',
            'content_type' => 'image',
            'media_id' => $deletedMedia->id,
        ])->assertUnprocessable()->assertJsonPath('code', 'INVALID_LESSON_MEDIA');

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/module-templates/{$templateId}/lessons", [
            'title' => 'URL',
            'content_type' => 'link',
            'external_url' => 'http://example.com',
        ])->assertUnprocessable()->assertJsonPath('code', 'INVALID_LESSON_CONTENT');

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/module-templates/{$templateId}/lessons", [
            'title' => 'Script',
            'content_type' => 'text',
            'content_body' => '<script>alert(1)</script>',
        ])->assertUnprocessable()->assertJsonPath('code', 'INVALID_LESSON_CONTENT');

        $otherTemplate = ModuleTemplate::factory()->create(['created_by' => $admin->id]);
        $otherLesson = LessonTemplate::factory()->create(['module_template_id' => $otherTemplate->id, 'created_by' => $admin->id]);
        $this->withToken($this->tokenFor($admin))->patchJson("/api/v1/admin/module-templates/{$templateId}/lessons/reorder", [
            'lesson_ids' => [$textLessonId, $otherLesson->id],
        ])->assertUnprocessable()->assertJsonPath('code', 'INVALID_ORDER');

        $ids = LessonTemplate::query()->where('module_template_id', $templateId)->orderByDesc('sort_order')->pluck('id')->all();
        $this->withToken($this->tokenFor($teacher))->patchJson("/api/v1/admin/module-templates/{$templateId}/lessons/reorder", [
            'lesson_ids' => $ids,
        ])->assertForbidden();
        $this->withToken($this->tokenFor($admin))->patchJson("/api/v1/admin/module-templates/{$templateId}/lessons/reorder", [
            'lesson_ids' => [$ids[0], $ids[0]],
        ])->assertUnprocessable()->assertJsonPath('code', 'INVALID_ORDER');
        $this->withToken($this->tokenFor($admin))->patchJson("/api/v1/admin/module-templates/{$templateId}/lessons/reorder", [
            'lesson_ids' => $ids,
        ])->assertOk();
        foreach ($ids as $index => $id) {
            $this->assertDatabaseHas('lesson_templates', ['id' => $id, 'sort_order' => $index + 1]);
        }

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/module-templates/{$templateId}/publish")
            ->assertOk()
            ->assertJsonPath('data.status', 'published');

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/module-templates/{$templateId}/archive")
            ->assertOk()
            ->assertJsonPath('data.status', 'archived');

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/module-templates/{$templateId}/publish")
            ->assertOk()
            ->assertJsonPath('data.status', 'published')
            ->assertJsonPath('data.archived_at', null);

        $this->assertDatabaseHas('audit_logs', ['action' => 'module_template.created']);
        $this->assertDatabaseHas('audit_logs', ['action' => 'lesson_template.created']);
        $this->assertDatabaseHas('audit_logs', ['action' => 'lesson_template.reordered']);
    }

    public function test_apply_template_creates_independent_snapshots_and_is_idempotent(): void
    {
        $admin = User::factory()->admin()->create();
        $teacher = User::factory()->teacher()->approved()->create();
        [$classA, $classB] = $this->classes($admin, 2);
        $inactiveSchool = School::factory()->inactive()->create(['created_by' => $admin->id]);
        $inactiveClass = SchoolClass::factory()->create(['school_id' => $inactiveSchool->id, 'created_by' => $admin->id]);
        $template = ModuleTemplate::factory()->published()->create(['created_by' => $admin->id, 'title' => 'Template Asli']);
        LessonTemplate::factory()->published()->create(['module_template_id' => $template->id, 'created_by' => $admin->id, 'sort_order' => 3]);

        $this->withToken($this->tokenFor($teacher))->postJson("/api/v1/admin/module-templates/{$template->id}/apply", [
            'class_ids' => [$classA->id],
        ])->assertForbidden();

        $response = $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/module-templates/{$template->id}/apply", [
            'class_ids' => [$classA->id, $classB->id, $inactiveClass->id],
        ])->assertOk();

        $this->assertCount(2, $response->json('data.applied'));
        $this->assertCount(1, $response->json('data.failed'));

        $copy = ClassModule::query()->where('class_id', $classA->id)->where('source_module_template_id', $template->id)->firstOrFail();
        $this->assertSame('draft', $copy->status);
        $this->assertSame(3, $copy->lessons()->firstOrFail()->sort_order);

        $template->update(['title' => 'Template Berubah']);
        $copy->update(['title' => 'Copy Berubah']);
        $this->assertSame('Copy Berubah', $copy->refresh()->title);
        $this->assertSame('Template Berubah', $template->refresh()->title);

        $second = $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/module-templates/{$template->id}/apply", [
            'class_ids' => [$classA->id],
        ])->assertOk();
        $this->assertCount(1, $second->json('data.skipped'));
        $this->assertSame(1, ClassModule::query()->where('class_id', $classA->id)->where('source_module_template_id', $template->id)->count());
        $this->assertDatabaseHas('audit_logs', ['action' => 'module_template.applied']);
    }

    public function test_publish_template_distribution_defaults_drafts_can_publish_and_excludes_inactive_targets(): void
    {
        $admin = User::factory()->admin()->create();
        [$classA, $classB] = $this->classes($admin, 2);
        $inactiveClass = SchoolClass::factory()->inactive()->create([
            'school_id' => $classA->school_id,
            'created_by' => $admin->id,
        ]);
        $inactiveSchool = School::factory()->inactive()->create(['created_by' => $admin->id]);
        $inactiveSchoolClass = SchoolClass::factory()->create([
            'school_id' => $inactiveSchool->id,
            'created_by' => $admin->id,
        ]);
        $student = $this->studentFor($classA, $admin);
        $template = ModuleTemplate::factory()->create(['created_by' => $admin->id]);
        LessonTemplate::factory()->published()->create([
            'module_template_id' => $template->id,
            'created_by' => $admin->id,
            'content_type' => 'text',
            'content_body' => 'Materi distribusi',
        ]);

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/module-templates/{$template->id}/publish")
            ->assertOk()
            ->assertJsonPath('data.status', 'published')
            ->assertJsonPath('data.distribution', null);
        $this->assertSame(0, ClassModule::query()->where('source_module_template_id', $template->id)->count());

        $draftResponse = $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/module-templates/{$template->id}/publish", [
            'apply_to_all_active_classes' => true,
        ])->assertOk();
        $this->assertCount(2, $draftResponse->json('data.distribution.applied'));
        $this->assertSame(2, ClassModule::query()->where('source_module_template_id', $template->id)->where('status', 'draft')->count());
        $this->assertDatabaseMissing('class_modules', ['class_id' => $inactiveClass->id, 'source_module_template_id' => $template->id]);
        $this->assertDatabaseMissing('class_modules', ['class_id' => $inactiveSchoolClass->id, 'source_module_template_id' => $template->id]);
        $this->withToken($this->tokenFor($student))->getJson('/api/v1/student/modules')->assertOk()->assertJsonPath('meta.total', 0);

        $publishedTemplate = ModuleTemplate::factory()->create(['created_by' => $admin->id]);
        LessonTemplate::factory()->published()->create([
            'module_template_id' => $publishedTemplate->id,
            'created_by' => $admin->id,
            'content_type' => 'text',
            'content_body' => 'Materi langsung',
        ]);
        $publishedResponse = $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/module-templates/{$publishedTemplate->id}/publish", [
            'apply_to_all_active_classes' => true,
            'publish_class_modules' => true,
        ])->assertOk();
        $this->assertCount(2, $publishedResponse->json('data.distribution.applied'));
        $this->assertSame(2, ClassModule::query()->where('source_module_template_id', $publishedTemplate->id)->where('status', 'published')->count());
        $this->withToken($this->tokenFor($student))->getJson('/api/v1/student/modules')->assertOk()->assertJsonPath('meta.total', 1);
        $this->assertDatabaseHas('audit_logs', ['action' => 'class_module.published']);
    }

    public function test_publish_template_distribution_validates_boolean_dependency(): void
    {
        $admin = User::factory()->admin()->create();
        $template = ModuleTemplate::factory()->create(['created_by' => $admin->id]);
        LessonTemplate::factory()->published()->create(['module_template_id' => $template->id, 'created_by' => $admin->id]);

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/module-templates/{$template->id}/publish", [
            'apply_to_all_active_classes' => 'invalid',
        ])->assertUnprocessable()->assertJsonPath('code', 'VALIDATION_ERROR');
        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/module-templates/{$template->id}/publish", [
            'publish_class_modules' => true,
        ])->assertUnprocessable()
            ->assertJsonPath('code', 'VALIDATION_ERROR')
            ->assertJsonPath('errors.publish_class_modules.0', 'Opsi langsung tampil ke siswa hanya dapat dipilih jika salinan dikirim ke semua kelas aktif.');

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/module-templates/{$template->id}/publish", [
            'apply_to_all_active_classes' => false,
            'publish_class_modules' => false,
        ])->assertOk();
    }

    public function test_class_module_lesson_student_access_content_url_delete_and_media_usage(): void
    {
        $admin = User::factory()->admin()->create();
        [$classA, $classB] = $this->classes($admin, 2);
        $teacherA = $this->teacherFor($classA, $admin);
        $teacherB = $this->teacherFor($classB, $admin);
        $studentA = $this->studentFor($classA, $admin);
        $studentB = $this->studentFor($classB, $admin);
        $privatePdf = $this->media($teacherA, 'document', $this->pdfFile(), 'private');

        $this->withToken($this->tokenFor($teacherA))->postJson("/api/v1/classes/{$classB->id}/modules", ['title' => 'Salah'])
            ->assertForbidden();
        $this->withToken($this->tokenFor($studentA))->postJson("/api/v1/classes/{$classA->id}/modules", ['title' => 'Siswa'])
            ->assertForbidden();

        $moduleId = $this->withToken($this->tokenFor($teacherA))->postJson("/api/v1/classes/{$classA->id}/modules", [
            'title' => 'Modul Guru',
        ])->assertCreated()->json('data.id');

        $this->withToken($this->tokenFor($teacherB))->putJson("/api/v1/class-modules/{$moduleId}", ['title' => 'Ambil'])
            ->assertForbidden();

        $lessonId = $this->withToken($this->tokenFor($teacherA))->postJson("/api/v1/class-modules/{$moduleId}/lessons", [
            'title' => 'PDF',
            'content_type' => 'pdf',
            'media_id' => $privatePdf->id,
            'status' => 'published',
        ])->assertCreated()->json('data.id');
        $this->withToken($this->tokenFor($teacherA))->postJson("/api/v1/class-modules/{$moduleId}/publish")->assertOk();

        $this->withToken($this->tokenFor($studentA))->getJson('/api/v1/student/modules')
            ->assertOk()
            ->assertJsonPath('meta.total', 1);
        $this->withToken($this->tokenFor($studentB))->getJson("/api/v1/student/modules/{$moduleId}")
            ->assertNotFound();
        $this->withToken($this->tokenFor($studentA))->getJson("/api/v1/class-lessons/{$lessonId}/content-url")
            ->assertOk()
            ->assertJsonMissingPath('data.media.path')
            ->assertJsonPath('data.media.visibility', 'private')
            ->assertJsonPath('data.media.size_bytes', $privatePdf->size_bytes)
            ->assertJsonPath('data.media.checksum_sha256', $privatePdf->checksum_sha256)
            ->assertJsonPath('data.media.extension', $privatePdf->extension)
            ->assertJsonPath('data.media.updated_at', $privatePdf->updated_at->toISOString());
        $this->withToken($this->tokenFor($studentB))->getJson("/api/v1/class-lessons/{$lessonId}/content-url")
            ->assertNotFound()
            ->assertJsonMissingPath('data.media');

        $this->withToken($this->tokenFor($teacherA))->deleteJson("/api/v1/media/{$privatePdf->id}")
            ->assertConflict()
            ->assertJsonPath('code', 'MEDIA_IN_USE');

        $this->withToken($this->tokenFor($teacherA))->deleteJson("/api/v1/class-lessons/{$lessonId}")
            ->assertConflict()
            ->assertJsonPath('code', 'LESSON_MUST_BE_ARCHIVED');
        $this->withToken($this->tokenFor($teacherA))->deleteJson("/api/v1/class-modules/{$moduleId}")
            ->assertConflict()
            ->assertJsonPath('code', 'MODULE_MUST_BE_ARCHIVED');

        $this->withToken($this->tokenFor($studentA))->postJson("/api/v1/student/modules/{$moduleId}/start")->assertOk();
        $this->withToken($this->tokenFor($studentA))->patchJson("/api/v1/student/lessons/{$lessonId}/progress", [
            'status' => 'in_progress',
            'progress_percent' => 50,
        ])->assertOk();
        $this->withToken($this->tokenFor($teacherA))->postJson("/api/v1/class-lessons/{$lessonId}/archive")->assertOk();
        $this->withToken($this->tokenFor($teacherA))->postJson("/api/v1/class-modules/{$moduleId}/archive")->assertOk();
        $this->withToken($this->tokenFor($teacherA))->deleteJson("/api/v1/class-lessons/{$lessonId}")
            ->assertConflict()
            ->assertJsonPath('code', 'LESSON_HAS_PROGRESS');
        $this->withToken($this->tokenFor($teacherA))->deleteJson("/api/v1/class-modules/{$moduleId}")
            ->assertConflict()
            ->assertJsonPath('code', 'MODULE_HAS_PROGRESS');

        $this->assertDatabaseHas('audit_logs', ['action' => 'class_module.created']);
        $this->assertDatabaseHas('audit_logs', ['action' => 'class_lesson.created']);
    }

    public function test_teacher_can_delete_published_module_and_lesson_after_archiving_when_no_student_progress(): void
    {
        $admin = User::factory()->admin()->create();
        [$class] = $this->classes($admin, 1);
        $teacher = $this->teacherFor($class, $admin);

        $moduleId = $this->withToken($this->tokenFor($teacher))->postJson("/api/v1/classes/{$class->id}/modules", [
            'title' => 'Modul Tanpa Progress',
        ])->assertCreated()->json('data.id');

        $lessonId = $this->withToken($this->tokenFor($teacher))->postJson("/api/v1/class-modules/{$moduleId}/lessons", [
            'title' => 'Teks',
            'content_type' => 'text',
            'content_body' => 'Isi materi',
            'status' => 'published',
        ])->assertCreated()->json('data.id');
        $this->withToken($this->tokenFor($teacher))->postJson("/api/v1/class-modules/{$moduleId}/publish")->assertOk();

        $this->withToken($this->tokenFor($teacher))->deleteJson("/api/v1/class-lessons/{$lessonId}")
            ->assertConflict()
            ->assertJsonPath('code', 'LESSON_MUST_BE_ARCHIVED');
        $this->withToken($this->tokenFor($teacher))->deleteJson("/api/v1/class-modules/{$moduleId}")
            ->assertConflict()
            ->assertJsonPath('code', 'MODULE_MUST_BE_ARCHIVED');

        $this->withToken($this->tokenFor($teacher))->postJson("/api/v1/class-lessons/{$lessonId}/archive")->assertOk();
        $this->withToken($this->tokenFor($teacher))->postJson("/api/v1/class-modules/{$moduleId}/archive")->assertOk();

        $this->withToken($this->tokenFor($teacher))->deleteJson("/api/v1/class-lessons/{$lessonId}")->assertOk();
        $this->withToken($this->tokenFor($teacher))->deleteJson("/api/v1/class-modules/{$moduleId}")->assertOk();

        $this->assertSoftDeleted('class_lessons', ['id' => $lessonId]);
        $this->assertSoftDeleted('class_modules', ['id' => $moduleId]);
    }

    public function test_deleting_lesson_or_module_renumbers_remaining_sort_order_sequentially(): void
    {
        $admin = User::factory()->admin()->create();
        [$class] = $this->classes($admin, 1);
        $teacher = $this->teacherFor($class, $admin);

        $moduleOneId = $this->withToken($this->tokenFor($teacher))->postJson("/api/v1/classes/{$class->id}/modules", ['title' => 'Modul 1'])
            ->assertCreated()->json('data.id');
        $moduleTwoId = $this->withToken($this->tokenFor($teacher))->postJson("/api/v1/classes/{$class->id}/modules", ['title' => 'Modul 2'])
            ->assertCreated()->json('data.id');
        $moduleThreeId = $this->withToken($this->tokenFor($teacher))->postJson("/api/v1/classes/{$class->id}/modules", ['title' => 'Modul 3'])
            ->assertCreated()->json('data.id');
        $this->assertDatabaseHas('class_modules', ['id' => $moduleOneId, 'sort_order' => 1]);
        $this->assertDatabaseHas('class_modules', ['id' => $moduleTwoId, 'sort_order' => 2]);
        $this->assertDatabaseHas('class_modules', ['id' => $moduleThreeId, 'sort_order' => 3]);

        $lessonOneId = $this->withToken($this->tokenFor($teacher))->postJson("/api/v1/class-modules/{$moduleOneId}/lessons", [
            'title' => 'Materi 1',
            'content_type' => 'text',
            'content_body' => 'Isi materi 1',
        ])->assertCreated()->json('data.id');
        $lessonTwoId = $this->withToken($this->tokenFor($teacher))->postJson("/api/v1/class-modules/{$moduleOneId}/lessons", [
            'title' => 'Materi 2',
            'content_type' => 'text',
            'content_body' => 'Isi materi 2',
        ])->assertCreated()->json('data.id');
        $this->assertDatabaseHas('class_lessons', ['id' => $lessonOneId, 'sort_order' => 1]);
        $this->assertDatabaseHas('class_lessons', ['id' => $lessonTwoId, 'sort_order' => 2]);

        $this->withToken($this->tokenFor($teacher))->deleteJson("/api/v1/class-lessons/{$lessonOneId}")->assertOk();
        $this->assertDatabaseHas('class_lessons', ['id' => $lessonTwoId, 'sort_order' => 1]);

        $this->withToken($this->tokenFor($teacher))->deleteJson("/api/v1/class-modules/{$moduleOneId}")->assertOk();
        $this->assertDatabaseHas('class_modules', ['id' => $moduleTwoId, 'sort_order' => 1]);
        $this->assertDatabaseHas('class_modules', ['id' => $moduleThreeId, 'sort_order' => 2]);
    }

    public function test_student_progress_is_idempotent_recalculated_and_scoped(): void
    {
        $admin = User::factory()->admin()->create();
        [$classA, $classB] = $this->classes($admin, 2);
        $studentA = $this->studentFor($classA, $admin);
        $studentB = $this->studentFor($classB, $admin);
        $module = ClassModule::factory()->published()->create(['class_id' => $classA->id, 'created_by' => $admin->id]);
        $lessonOne = ClassLesson::factory()->published()->create(['class_module_id' => $module->id, 'created_by' => $admin->id, 'sort_order' => 1]);
        $lessonTwo = ClassLesson::factory()->published()->create(['class_module_id' => $module->id, 'created_by' => $admin->id, 'sort_order' => 2]);

        $this->withToken($this->tokenFor($studentB))->patchJson("/api/v1/student/lessons/{$lessonOne->id}/progress", [
            'status' => 'completed',
        ])->assertNotFound();

        $this->withToken($this->tokenFor($studentA))->postJson("/api/v1/student/modules/{$module->id}/start")->assertOk();
        $this->withToken($this->tokenFor($studentA))->postJson("/api/v1/student/modules/{$module->id}/start")->assertOk();
        $this->assertSame(1, ModuleProgress::query()->where('student_id', $studentA->id)->where('class_module_id', $module->id)->count());

        $this->withToken($this->tokenFor($studentA))->patchJson("/api/v1/student/lessons/{$lessonOne->id}/progress", [
            'student_id' => $studentB->id,
            'status' => 'in_progress',
            'progress_percent' => 50,
        ])->assertOk()->assertJsonPath('data.progress_percent', 50);

        $this->assertDatabaseHas('module_progress', [
            'student_id' => $studentA->id,
            'class_module_id' => $module->id,
            'progress_percent' => 0,
        ]);

        $this->withToken($this->tokenFor($studentA))->patchJson("/api/v1/student/lessons/{$lessonOne->id}/progress", [
            'status' => 'completed',
        ])->assertOk()->assertJsonPath('data.progress_percent', 100);
        $lessonCompletedAt = LessonProgress::query()->where('student_id', $studentA->id)->where('class_lesson_id', $lessonOne->id)->value('completed_at');
        $this->withToken($this->tokenFor($studentA))->patchJson("/api/v1/student/lessons/{$lessonOne->id}/progress", [
            'status' => 'in_progress',
            'progress_percent' => 25,
        ])->assertOk()->assertJsonPath('data.status', 'completed')->assertJsonPath('data.progress_percent', 100);
        $this->assertEquals($lessonCompletedAt, LessonProgress::query()->where('student_id', $studentA->id)->where('class_lesson_id', $lessonOne->id)->value('completed_at'));
        $this->assertDatabaseHas('module_progress', ['student_id' => $studentA->id, 'class_module_id' => $module->id, 'progress_percent' => 50]);

        $this->withToken($this->tokenFor($studentA))->patchJson("/api/v1/student/lessons/{$lessonTwo->id}/progress", [
            'status' => 'completed',
        ])->assertOk();
        $moduleCompletedAt = ModuleProgress::query()->where('student_id', $studentA->id)->where('class_module_id', $module->id)->value('completed_at');
        $this->withToken($this->tokenFor($studentA))->patchJson("/api/v1/student/lessons/{$lessonTwo->id}/progress", [
            'status' => 'completed',
        ])->assertOk();
        $this->assertEquals($moduleCompletedAt, ModuleProgress::query()->where('student_id', $studentA->id)->where('class_module_id', $module->id)->value('completed_at'));
        $this->assertDatabaseHas('module_progress', ['student_id' => $studentA->id, 'class_module_id' => $module->id, 'status' => 'completed', 'progress_percent' => 100]);

        $newLesson = $this->withToken($this->tokenFor($admin))->postJson("/api/v1/class-modules/{$module->id}/lessons", [
            'title' => 'Baru',
            'content_type' => 'text',
            'content_body' => 'Materi baru',
            'status' => 'published',
        ])->assertCreated()->json('data.id');
        $this->assertDatabaseHas('module_progress', ['student_id' => $studentA->id, 'class_module_id' => $module->id, 'status' => 'in_progress', 'progress_percent' => 66]);

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/class-lessons/{$newLesson}/archive")->assertOk();
        $this->assertDatabaseHas('module_progress', ['student_id' => $studentA->id, 'class_module_id' => $module->id, 'status' => 'completed', 'progress_percent' => 100]);

        $this->withToken($this->tokenFor($studentA))->patchJson("/api/v1/student/lessons/{$lessonTwo->id}/progress", [
            'status' => 'in_progress',
            'progress_percent' => 0,
        ])->assertUnprocessable()->assertJsonPath('code', 'INVALID_PROGRESS');
    }

    private function classes(User $admin, int $count): array
    {
        $school = School::factory()->create(['created_by' => $admin->id]);

        return SchoolClass::factory()->count($count)->create(['school_id' => $school->id, 'created_by' => $admin->id])->all();
    }

    private function teacherFor(SchoolClass $class, User $admin): User
    {
        $teacher = User::factory()->teacher()->approved()->create();
        TeacherClassAssignment::factory()->create(['teacher_id' => $teacher->id, 'class_id' => $class->id, 'assigned_by' => $admin->id]);

        return $teacher;
    }

    private function studentFor(SchoolClass $class, User $admin): User
    {
        $student = User::factory()->student()->approved()->create();
        StudentClassMembership::factory()->create(['student_id' => $student->id, 'class_id' => $class->id, 'assigned_by' => $admin->id]);

        return $student;
    }

    private function media(User $user, string $purpose, UploadedFile $file, string $visibility): MediaFile
    {
        $response = $this->withToken($this->tokenFor($user))->post('/api/v1/media', [
            'file' => $file,
            'purpose' => $purpose,
            'visibility' => $visibility,
        ])->assertCreated();

        return MediaFile::query()->findOrFail($response->json('data.id'));
    }

    private function tokenFor(User $user): string
    {
        $this->app['auth']->forgetGuards();

        return $user->createToken('PHPUnit')->plainTextToken;
    }

    private function pngFile(string $name = 'lesson.png'): UploadedFile
    {
        return UploadedFile::fake()->createWithContent($name, base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII='));
    }

    private function pdfFile(string $name = 'materi.pdf'): UploadedFile
    {
        return UploadedFile::fake()->createWithContent($name, "%PDF-1.4\n%%EOF");
    }

    private function mp3File(string $name = 'audio.mp3'): UploadedFile
    {
        return UploadedFile::fake()->createWithContent($name, "\xFF\xFB\x90\x64".str_repeat("\x00", 1024));
    }
}
