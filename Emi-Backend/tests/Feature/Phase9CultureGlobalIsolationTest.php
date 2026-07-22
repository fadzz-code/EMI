<?php

namespace Tests\Feature;

use App\Models\AdminCultureItem;
use App\Models\ClassCultureItem;
use App\Models\School;
use App\Models\SchoolClass;
use App\Models\StudentClassMembership;
use App\Models\TeacherClassAssignment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class Phase9CultureGlobalIsolationTest extends TestCase
{
    use RefreshDatabase;

    public function test_teacher_actions_on_admin_global_culture_item_stay_class_scoped(): void
    {
        $admin = User::factory()->admin()->create();
        [$classA, $classB] = $this->classes($admin, 2);
        $teacherA = $this->teacherFor($classA, $admin);
        $studentA = $this->studentFor($classA, $admin);
        $studentB = $this->studentFor($classB, $admin);

        $groupId = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/culture/items', [
            'title' => 'Sejarah Mekongga',
            'description' => 'Konten dari admin',
            'content_type' => 'link',
            'external_url' => 'https://example.com/sejarah',
            'display_order' => 1,
            'status' => 'published',
        ])->assertCreated()->json('data.id');

        $this->assertDatabaseHas('admin_culture_items', [
            'admin_group_id' => $groupId,
            'title' => 'Sejarah Mekongga',
            'status' => 'published',
        ]);

        $copies = ClassCultureItem::query()->where('admin_group_id', $groupId)->orderBy('class_id')->get();
        $this->assertCount(2, $copies);
        $copyA = $copies->firstWhere('class_id', $classA->id);
        $copyB = $copies->firstWhere('class_id', $classB->id);
        $this->assertNotNull($copyA);
        $this->assertNotNull($copyB);

        $this->withToken($this->tokenFor($teacherA))->putJson("/api/v1/class-culture-items/{$copyA->id}", [
            'title' => 'Edit Kelas A',
            'description' => 'Hanya kelas A',
            'content_type' => 'link',
            'external_url' => 'https://example.com/kelas-a',
            'display_order' => 1,
            'status' => 'published',
        ])->assertOk();

        $this->assertDatabaseHas('class_culture_items', [
            'id' => $copyA->id,
            'title' => 'Edit Kelas A',
            'admin_group_id' => null,
            'created_scope' => 'teacher',
        ]);
        $this->assertDatabaseHas('class_culture_items', [
            'id' => $copyB->id,
            'title' => 'Sejarah Mekongga',
            'admin_group_id' => $groupId,
            'created_scope' => 'admin',
        ]);
        $this->assertDatabaseHas('admin_culture_items', [
            'admin_group_id' => $groupId,
            'title' => 'Sejarah Mekongga',
        ]);
        $this->withToken($this->tokenFor($admin))->getJson('/api/v1/admin/culture/items')
            ->assertOk()
            ->assertJsonPath('data.0.id', $groupId)
            ->assertJsonPath('data.0.title', 'Sejarah Mekongga')
            ->assertJsonPath('meta.total', 1);

        $this->withToken($this->tokenFor($teacherA))->deleteJson("/api/v1/class-culture-items/{$copyA->id}")
            ->assertOk();

        $this->assertSoftDeleted('class_culture_items', ['id' => $copyA->id]);
        $this->assertDatabaseHas('class_culture_items', ['id' => $copyB->id, 'deleted_at' => null]);

        $this->withToken($this->tokenFor($admin))->getJson('/api/v1/admin/culture/items')
            ->assertOk()
            ->assertJsonPath('data.0.id', $groupId)
            ->assertJsonPath('data.0.title', 'Sejarah Mekongga')
            ->assertJsonPath('meta.total', 1);

        $studentAItems = $this->withToken($this->tokenFor($studentA))->getJson('/api/v1/student/culture')
            ->assertOk()
            ->json('data');
        $studentBItems = $this->withToken($this->tokenFor($studentB))->getJson('/api/v1/student/culture')
            ->assertOk()
            ->json('data');

        $this->assertEmpty($studentAItems);
        $this->assertSame('Sejarah Mekongga', $studentBItems[0]['title']);
    }

    public function test_admin_list_detail_search_filters_pagination_and_group_path(): void
    {
        $admin = User::factory()->admin()->create();
        $this->classes($admin, 1);
        $first = $this->createItem($admin, ['title' => 'Alfa Budaya', 'content_type' => 'link', 'external_url' => 'https://example.com/alfa']);
        $this->createItem($admin, ['title' => 'Beta Budaya', 'content_type' => 'article', 'external_url' => 'https://example.com/beta', 'status' => 'published']);

        $this->admin($admin)->getJson('/api/v1/admin/culture/items?search=Alfa&status=draft&content_type=link&per_page=1&page=1')
            ->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.id', $first)
            ->assertJsonPath('meta.current_page', 1)->assertJsonPath('meta.per_page', 1)
            ->assertJsonPath('meta.total', 1)->assertJsonPath('meta.last_page', 1);
        $this->admin($admin)->getJson("/api/v1/admin/culture/items/{$first}")
            ->assertOk()->assertJsonPath('data.id', $first)->assertJsonPath('data.title', 'Alfa Budaya');
    }

    public function test_admin_can_create_draft_update_and_retain_omitted_media(): void
    {
        Storage::fake('public');
        $admin = User::factory()->admin()->create();
        $this->classes($admin, 1);
        $media = $this->uploadCultureMedia($admin, $this->pngFile())->assertCreated()->json('data.id');
        $id = $this->createItem($admin, ['title' => 'Gambar', 'content_type' => 'image', 'media_id' => $media]);

        $this->admin($admin)->putJson("/api/v1/admin/culture/items/{$id}", ['title' => 'Gambar Baru'])
            ->assertOk()->assertJsonPath('data.title', 'Gambar Baru')->assertJsonPath('data.media.id', $media);
        $this->assertDatabaseHas('admin_culture_items', ['admin_group_id' => $id, 'media_id' => $media, 'status' => 'draft']);
    }

    public function test_publish_valid_archive_and_republish_clear_archive_timestamp(): void
    {
        $admin = User::factory()->admin()->create();
        $this->classes($admin, 1);
        $id = $this->createItem($admin);

        $this->admin($admin)->postJson("/api/v1/admin/culture/items/{$id}/publish")->assertOk()->assertJsonPath('data.status', 'published');
        $this->admin($admin)->postJson("/api/v1/admin/culture/items/{$id}/archive")->assertOk()->assertJsonPath('data.status', 'archived');
        $this->assertNotNull(AdminCultureItem::query()->where('admin_group_id', $id)->firstOrFail()->archived_at);
        $this->admin($admin)->postJson("/api/v1/admin/culture/items/{$id}/publish")->assertOk();
        $this->assertNull(AdminCultureItem::query()->where('admin_group_id', $id)->firstOrFail()->archived_at);
    }

    public function test_publish_invalid_and_direct_published_create_or_update_are_rejected(): void
    {
        $admin = User::factory()->admin()->create();
        $this->classes($admin, 1);
        $id = $this->createItem($admin);
        AdminCultureItem::query()->where('admin_group_id', $id)->update(['external_url' => null]);

        $this->admin($admin)->postJson("/api/v1/admin/culture/items/{$id}/publish")->assertUnprocessable();
        $this->admin($admin)->postJson('/api/v1/admin/culture/items', ['title' => 'Invalid', 'content_type' => 'link', 'status' => 'published'])->assertUnprocessable();
        $this->admin($admin)->putJson("/api/v1/admin/culture/items/{$id}", ['status' => 'published'])->assertUnprocessable();
    }

    public function test_delete_soft_deletes_master_and_attached_global_copies(): void
    {
        $admin = User::factory()->admin()->create();
        $this->classes($admin, 2);
        $id = $this->createItem($admin);
        $copies = ClassCultureItem::query()->where('admin_group_id', $id)->get();

        $this->admin($admin)->deleteJson("/api/v1/admin/culture/items/{$id}")->assertOk();
        $this->assertSoftDeleted('admin_culture_items', ['admin_group_id' => $id]);
        foreach ($copies as $copy) {
            $this->assertSoftDeleted('class_culture_items', ['id' => $copy->id]);
        }
        $this->admin($admin)->getJson("/api/v1/admin/culture/items/{$id}")->assertNotFound();
    }

    public function test_global_item_propagates_but_admin_response_is_not_class_bound(): void
    {
        $admin = User::factory()->admin()->create();
        $this->classes($admin, 2);
        $id = $this->createItem($admin);

        $this->assertSame(2, ClassCultureItem::query()->where('admin_group_id', $id)->where('created_scope', 'admin')->count());
        $this->admin($admin)->getJson("/api/v1/admin/culture/items/{$id}")
            ->assertOk()->assertJsonPath('data.id', $id)->assertJsonPath('data.classes_count', 2)
            ->assertJsonMissingPath('data.class_id');
    }

    public function test_valid_image_media_association_and_safe_nested_response(): void
    {
        Storage::fake('public');
        $admin = User::factory()->admin()->create();
        $this->classes($admin, 1);
        $media = $this->uploadCultureMedia($admin, $this->pngFile())->assertCreated()->json('data.id');
        $id = $this->createItem($admin, ['content_type' => 'image', 'media_id' => $media]);

        $response = $this->admin($admin)->getJson("/api/v1/admin/culture/items/{$id}")->assertOk()->assertJsonPath('data.media.id', $media);
        foreach (['admin_group_id', 'media_id', 'created_scope', 'path', 'disk', 'stored_name'] as $field) {
            $response->assertJsonMissingPath("data.{$field}")->assertJsonMissingPath("data.media.{$field}");
        }
    }

    public function test_wrong_mime_media_association_is_rejected(): void
    {
        Storage::fake('public');
        $admin = User::factory()->admin()->create();
        $this->classes($admin, 1);
        $media = $this->uploadCultureMedia($admin, $this->pdfFile())->assertCreated()->json('data.id');

        $this->admin($admin)->postJson('/api/v1/admin/culture/items', $this->payload(['content_type' => 'image', 'media_id' => $media]))->assertUnprocessable();
    }

    public function test_oversize_culture_media_upload_is_rejected(): void
    {
        Storage::fake('public');
        config(['media.max_kb.document' => 1]);
        $admin = User::factory()->admin()->create();

        $this->uploadCultureMedia($admin, UploadedFile::fake()->create('large.pdf', 2, 'application/pdf'))
            ->assertUnprocessable()->assertJsonPath('code', 'MEDIA_FILE_TOO_LARGE');
    }

    public function test_teacher_student_and_guest_are_denied_admin_culture_endpoints(): void
    {
        $teacher = User::factory()->teacher()->approved()->create();
        $student = User::factory()->student()->approved()->create();

        $this->withHeaders(['Accept' => 'application/json'])->get('/api/v1/admin/culture/items')->assertUnauthorized();
        $this->admin($teacher)->getJson('/api/v1/admin/culture/items')->assertForbidden();
        $this->admin($student)->getJson('/api/v1/admin/culture/items')->assertForbidden();
    }

    public function test_teacher_direct_class_culture_crud_and_media_transitions(): void
    {
        Storage::fake('public');
        $admin = User::factory()->admin()->create();
        [$class] = $this->classes($admin, 1);
        $teacher = $this->teacherFor($class, $admin);
        $firstMedia = $this->uploadCultureMedia($teacher, $this->pngFile())->assertCreated()->json('data.id');
        $secondMedia = $this->uploadCultureMedia($teacher, $this->pngFile())->assertCreated()->json('data.id');

        $id = $this->admin($teacher)->postJson("/api/v1/classes/{$class->id}/culture", $this->payload([
            'title' => 'Budaya Kelas',
            'content_type' => 'image',
            'external_url' => null,
            'media_id' => $firstMedia,
        ]))->assertCreated()->assertJsonPath('data.media.id', $firstMedia)->json('data.id');

        $this->admin($teacher)->getJson("/api/v1/classes/{$class->id}/culture")
            ->assertOk()->assertJsonPath('data.0.id', $id);
        $this->admin($teacher)->getJson("/api/v1/class-culture-items/{$id}")
            ->assertOk()->assertJsonPath('data.title', 'Budaya Kelas');
        $this->admin($teacher)->putJson("/api/v1/class-culture-items/{$id}", $this->payload([
            'title' => 'Media Tetap',
            'content_type' => 'image',
            'external_url' => null,
            'media_id' => $firstMedia,
        ]))->assertOk()->assertJsonPath('data.media.id', $firstMedia);
        $this->admin($teacher)->putJson("/api/v1/class-culture-items/{$id}", $this->payload([
            'title' => 'Media Ganti',
            'content_type' => 'image',
            'external_url' => null,
            'media_id' => $secondMedia,
        ]))->assertOk()->assertJsonPath('data.media.id', $secondMedia);
        $this->admin($teacher)->putJson("/api/v1/class-culture-items/{$id}", $this->payload([
            'title' => 'Media Hapus',
            'media_id' => null,
        ]))->assertOk()->assertJsonPath('data.media_id', null);
        $this->admin($teacher)->postJson("/api/v1/class-culture-items/{$id}/publish")
            ->assertOk()->assertJsonPath('data.status', 'published');
        $this->admin($teacher)->postJson("/api/v1/class-culture-items/{$id}/archive")
            ->assertOk()->assertJsonPath('data.status', 'archived');
        $this->admin($teacher)->deleteJson("/api/v1/class-culture-items/{$id}")->assertOk();
        $this->assertSoftDeleted('class_culture_items', ['id' => $id]);
    }

    public function test_class_culture_management_requires_own_active_assignment_and_management_role(): void
    {
        $admin = User::factory()->admin()->create();
        [$ownClass, $foreignClass] = $this->classes($admin, 2);
        $teacher = $this->teacherFor($ownClass, $admin);
        $foreignItem = ClassCultureItem::query()->create(array_merge($this->payload(), ['class_id' => $foreignClass->id, 'created_by' => $admin->id]));
        $student = $this->studentFor($ownClass, $admin);

        $this->admin($teacher)->getJson("/api/v1/classes/{$foreignClass->id}/culture")->assertForbidden();
        $this->admin($teacher)->putJson("/api/v1/class-culture-items/{$foreignItem->id}", $this->payload())->assertForbidden();
        $this->admin($student)->getJson("/api/v1/classes/{$ownClass->id}/culture")->assertForbidden();
        $this->flushHeaders();
        $this->app['auth']->forgetGuards();
        $this->getJson("/api/v1/classes/{$ownClass->id}/culture")->assertUnauthorized();

        TeacherClassAssignment::query()->where('teacher_id', $teacher->id)->update(['is_active' => false]);
        $this->admin($teacher)->getJson("/api/v1/classes/{$ownClass->id}/culture")->assertForbidden();
        $this->admin($teacher)->postJson("/api/v1/classes/{$ownClass->id}/culture", $this->payload())->assertForbidden();
    }

    public function test_teacher_cannot_manage_item_when_class_or_school_is_inactive_but_admin_can(): void
    {
        $admin = User::factory()->admin()->create();
        [$class] = $this->classes($admin, 1);
        $teacher = $this->teacherFor($class, $admin);
        $item = ClassCultureItem::query()->create(array_merge($this->payload(), ['class_id' => $class->id, 'created_by' => $teacher->id]));

        foreach ([['class', $class], ['school', $class->school]] as [$inactiveType, $model]) {
            $model->update(['status' => 'inactive']);
            foreach (['PUT' => '', 'POST' => '/publish', 'POST ' => '/archive', 'DELETE' => ''] as $method => $suffix) {
                $this->admin($teacher)->json(trim($method), "/api/v1/class-culture-items/{$item->id}{$suffix}", $method === 'PUT' ? $this->payload() : [])
                    ->assertForbidden("{$inactiveType} {$suffix}");
            }
            $model->update(['status' => 'active']);
        }

        $class->update(['status' => 'inactive']);
        $this->admin($admin)->putJson("/api/v1/class-culture-items/{$item->id}", $this->payload(['title' => 'Admin Tetap Bisa']))
            ->assertOk()->assertJsonPath('data.title', 'Admin Tetap Bisa');
    }

    public function test_teacher_cannot_associate_another_users_public_culture_media(): void
    {
        Storage::fake('public');
        $admin = User::factory()->admin()->create();
        [$class] = $this->classes($admin, 1);
        $teacher = $this->teacherFor($class, $admin);
        $otherTeacher = User::factory()->teacher()->approved()->create();
        $media = $this->uploadCultureMedia($otherTeacher, $this->pngFile())->assertCreated()->json('data.id');

        $this->admin($teacher)->postJson("/api/v1/classes/{$class->id}/culture", $this->payload([
            'content_type' => 'image',
            'external_url' => null,
            'media_id' => $media,
        ]))->assertForbidden()->assertJsonPath('code', 'MEDIA_FORBIDDEN');

        $this->admin($admin)->postJson('/api/v1/admin/culture/items', $this->payload([
            'content_type' => 'image',
            'external_url' => null,
            'media_id' => $media,
        ]))->assertCreated();
    }

    private function createItem(User $admin, array $overrides = []): string
    {
        return $this->admin($admin)->postJson('/api/v1/admin/culture/items', $this->payload($overrides))->assertCreated()->json('data.id');
    }

    private function payload(array $overrides = []): array
    {
        return array_merge(['title' => 'Budaya Global', 'content_type' => 'link', 'external_url' => 'https://example.com/budaya', 'status' => 'draft'], $overrides);
    }

    private function admin(User $user)
    {
        return $this->withToken($this->tokenFor($user));
    }

    private function uploadCultureMedia(User $admin, UploadedFile $file)
    {
        return $this->admin($admin)->post('/api/v1/media', ['file' => $file, 'purpose' => 'culture_media', 'visibility' => 'public']);
    }

    private function pngFile(): UploadedFile
    {
        return UploadedFile::fake()->createWithContent('culture.png', base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII='));
    }

    private function pdfFile(): UploadedFile
    {
        return UploadedFile::fake()->createWithContent('culture.pdf', "%PDF-1.4\n1 0 obj\n<<>>\nendobj\ntrailer\n<<>>\n%%EOF");
    }

    private function classes(User $admin, int $count): array
    {
        $school = School::factory()->create(['created_by' => $admin->id]);

        return collect(range(1, $count))->map(fn (int $index) => SchoolClass::factory()->create([
            'school_id' => $school->id,
            'name' => "Kelas Culture {$index}",
            'academic_year' => '2026/2027',
            'created_by' => $admin->id,
        ]))->all();
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

    private function tokenFor(User $user): string
    {
        $this->app['auth']->forgetGuards();

        return $user->createToken('PHPUnit')->plainTextToken;
    }
}
