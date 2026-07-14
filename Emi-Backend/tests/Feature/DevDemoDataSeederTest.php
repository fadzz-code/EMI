<?php

namespace Tests\Feature;

use App\Models\DictionaryCategory;
use App\Models\DictionaryEntry;
use App\Models\School;
use App\Models\SchoolClass;
use App\Models\StudentClassMembership;
use App\Models\TeacherClassAssignment;
use App\Models\User;
use Database\Seeders\DevDemoDataSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use InvalidArgumentException;
use Tests\TestCase;

class DevDemoDataSeederTest extends TestCase
{
    use RefreshDatabase;

    public function test_seeder_creates_exactly_three_target_accounts_with_correct_roles_and_status(): void
    {
        $this->seed(DevDemoDataSeeder::class);

        $this->assertGreaterThanOrEqual(3, User::count());

        $admin = User::where('email', 'admin@emi.test')->firstOrFail();
        $this->assertSame('admin', $admin->role);
        $this->assertSame('approved', $admin->status);
        $this->assertTrue(Hash::check('12345678', $admin->password));
        $this->assertNotSame('12345678', $admin->password);
        $this->assertNotNull($admin->email_verified_at);

        $this->assertSame(1, User::where('email', 'admin@emi.test')->count());
        $this->assertSame(1, User::where('email', 'teacher@emi.test')->count());
        $this->assertSame(1, User::where('email', 'student@emi.test')->count());

        $teacher = User::where('email', 'teacher@emi.test')->firstOrFail();
        $this->assertSame('teacher', $teacher->role);
        $this->assertSame('approved', $teacher->status);
        $this->assertTrue(Hash::check('12345678', $teacher->password));
        $this->assertNotNull($teacher->activeTeacherClassAssignment);
        $this->assertContains($teacher->activeTeacherClassAssignment->schoolClass->name, ['Kelas VII A', 'Kelas 1 A']);
        $this->assertDatabaseMissing('classes', ['name' => 'Kelas Demo Tiga Role']);

        $student = User::where('email', 'student@emi.test')->firstOrFail();
        $this->assertSame('student', $student->role);
        $this->assertSame('approved', $student->status);
        $this->assertTrue(Hash::check('12345678', $student->password));
        $this->assertNotNull($student->activeStudentClassMembership);
    }

    public function test_seeder_is_idempotent_and_does_not_create_duplicates_or_remove_other_data(): void
    {
        // Setup existing unrelated data
        User::factory()->create(['email' => 'other@example.com']);
        $school = School::factory()->create();
        SchoolClass::factory()->create(['school_id' => $school->id]);

        $initialCount = User::count();

        $this->seed(DevDemoDataSeeder::class);

        $this->assertGreaterThanOrEqual($initialCount + 3, User::count());

        // Mess up the target accounts
        User::where('email', 'admin@emi.test')->update(['role' => 'student', 'status' => 'inactive', 'password' => Hash::make('wrong')]);

        // Re-run seeder
        $this->seed(DevDemoDataSeeder::class);

        $this->assertSame(1, User::where('email', 'admin@emi.test')->count());
        $this->assertSame(1, User::where('email', 'teacher@emi.test')->count());
        $this->assertSame(1, User::where('email', 'student@emi.test')->count());

        // Check if admin is restored
        $admin = User::where('email', 'admin@emi.test')->firstOrFail();
        $this->assertSame('admin', $admin->role);
        $this->assertSame('approved', $admin->status);
        $this->assertTrue(Hash::check('12345678', $admin->password));
        $this->assertSame(1, TeacherClassAssignment::where('teacher_id', User::where('email', 'teacher@emi.test')->value('id'))->where('is_active', true)->count());
        $this->assertSame(1, StudentClassMembership::where('student_id', User::where('email', 'student@emi.test')->value('id'))->where('is_active', true)->count());
        $this->assertGreaterThan(0, DictionaryCategory::count());
        $this->assertGreaterThan(0, DictionaryEntry::count());
    }

    public function test_seeder_throws_exception_in_production(): void
    {
        $this->expectException(InvalidArgumentException::class);
        $this->expectExceptionMessage('Seeder demo development hanya boleh dijalankan di environment local, testing, atau development.');

        app()->detectEnvironment(function () {
            return 'production';
        });

        $seeder = new DevDemoDataSeeder;
        $seeder->run();
    }

    public function test_accounts_can_login_successfully(): void
    {
        $this->seed(DevDemoDataSeeder::class);

        $this->postJson('/api/v1/auth/login', [
            'email' => 'admin@emi.test',
            'password' => '12345678',
            'device_name' => 'Test',
        ])->assertOk()->assertJsonPath('data.user.role', 'admin');

        $this->postJson('/api/v1/auth/login', [
            'email' => 'teacher@emi.test',
            'password' => '12345678',
            'device_name' => 'Test',
        ])->assertOk()->assertJsonPath('data.user.role', 'teacher');

        $this->postJson('/api/v1/auth/login', [
            'email' => 'student@emi.test',
            'password' => '12345678',
            'device_name' => 'Test',
        ])->assertOk()->assertJsonPath('data.user.role', 'student');
    }
}
