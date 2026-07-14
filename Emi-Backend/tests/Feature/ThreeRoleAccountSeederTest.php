<?php

namespace Tests\Feature;

use App\Models\School;
use App\Models\SchoolClass;
use App\Models\User;
use Database\Seeders\ThreeRoleAccountSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use InvalidArgumentException;
use Tests\TestCase;

class ThreeRoleAccountSeederTest extends TestCase
{
    use RefreshDatabase;

    public function test_seeder_creates_exactly_three_target_accounts_with_correct_roles_and_status(): void
    {
        $this->seed(ThreeRoleAccountSeeder::class);

        $this->assertDatabaseCount('users', 3);

        $admin = User::where('email', 'admin@emi.test')->firstOrFail();
        $this->assertSame('admin', $admin->role);
        $this->assertSame('approved', $admin->status);
        $this->assertTrue(Hash::check('12345678', $admin->password));
        $this->assertNotNull($admin->email_verified_at);

        $teacher = User::where('email', 'teacher@emi.test')->firstOrFail();
        $this->assertSame('teacher', $teacher->role);
        $this->assertSame('approved', $teacher->status);
        $this->assertTrue(Hash::check('12345678', $teacher->password));
        $this->assertNotNull($teacher->activeTeacherClassAssignment);

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

        $this->seed(ThreeRoleAccountSeeder::class);

        $this->assertDatabaseCount('users', $initialCount + 3); // 3 target + existing

        // Mess up the target accounts
        User::where('email', 'admin@emi.test')->update(['role' => 'student', 'status' => 'inactive', 'password' => Hash::make('wrong')]);

        // Re-run seeder
        $this->seed(ThreeRoleAccountSeeder::class);

        $this->assertDatabaseCount('users', $initialCount + 3); // Still same

        // Check if admin is restored
        $admin = User::where('email', 'admin@emi.test')->firstOrFail();
        $this->assertSame('admin', $admin->role);
        $this->assertSame('approved', $admin->status);
        $this->assertTrue(Hash::check('12345678', $admin->password));
    }

    public function test_seeder_throws_exception_in_production(): void
    {
        $this->expectException(InvalidArgumentException::class);
        $this->expectExceptionMessage('Seeder akun demo statis hanya boleh dijalankan di environment local atau testing.');

        app()->detectEnvironment(function () {
            return 'production';
        });

        $seeder = new ThreeRoleAccountSeeder;
        $seeder->run();
    }

    public function test_accounts_can_login_successfully(): void
    {
        $this->seed(ThreeRoleAccountSeeder::class);

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
