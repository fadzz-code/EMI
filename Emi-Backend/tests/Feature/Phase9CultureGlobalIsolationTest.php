<?php

namespace Tests\Feature;

use App\Models\ClassCultureItem;
use App\Models\School;
use App\Models\SchoolClass;
use App\Models\StudentClassMembership;
use App\Models\TeacherClassAssignment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
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
        ])->assertCreated()->json('data.admin_group_id');

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
            ->assertJsonPath('data.0.admin_group_id', $groupId)
            ->assertJsonPath('data.0.title', 'Sejarah Mekongga');

        $this->withToken($this->tokenFor($teacherA))->deleteJson("/api/v1/class-culture-items/{$copyA->id}")
            ->assertOk();

        $this->assertSoftDeleted('class_culture_items', ['id' => $copyA->id]);
        $this->assertDatabaseHas('class_culture_items', ['id' => $copyB->id, 'deleted_at' => null]);

        $this->withToken($this->tokenFor($admin))->getJson('/api/v1/admin/culture/items')
            ->assertOk()
            ->assertJsonPath('data.0.admin_group_id', $groupId)
            ->assertJsonPath('data.0.title', 'Sejarah Mekongga');

        $studentAItems = $this->withToken($this->tokenFor($studentA))->getJson('/api/v1/student/culture')
            ->assertOk()
            ->json('data');
        $studentBItems = $this->withToken($this->tokenFor($studentB))->getJson('/api/v1/student/culture')
            ->assertOk()
            ->json('data');

        $this->assertEmpty($studentAItems);
        $this->assertSame('Sejarah Mekongga', $studentBItems[0]['title']);
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
