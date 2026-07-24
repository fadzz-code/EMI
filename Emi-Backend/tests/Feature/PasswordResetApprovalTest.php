<?php

namespace Tests\Feature;

use App\Models\PasswordResetRequest;
use App\Models\School;
use App\Models\SchoolClass;
use App\Models\StudentClassMembership;
use App\Models\TeacherClassAssignment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class PasswordResetApprovalTest extends TestCase
{
    use RefreshDatabase;

    private User $teacherA;

    private User $teacherB;

    private User $studentA;

    private User $studentB;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();

        $this->admin = User::factory()->admin()->approved()->create();

        $school = School::factory()->create();
        $classA = SchoolClass::factory()->create(['school_id' => $school->id]);
        $classB = SchoolClass::factory()->create(['school_id' => $school->id]);

        $this->teacherA = User::factory()->teacher()->approved()->create();
        $this->teacherB = User::factory()->teacher()->approved()->create();
        $this->studentA = User::factory()->student()->approved()->create(['password' => Hash::make('OldPassword123')]);
        $this->studentB = User::factory()->student()->approved()->create();

        TeacherClassAssignment::factory()->create(['teacher_id' => $this->teacherA->id, 'class_id' => $classA->id, 'is_active' => true]);
        TeacherClassAssignment::factory()->create(['teacher_id' => $this->teacherB->id, 'class_id' => $classB->id, 'is_active' => true]);
        StudentClassMembership::factory()->create(['student_id' => $this->studentA->id, 'class_id' => $classA->id, 'is_active' => true]);
        StudentClassMembership::factory()->create(['student_id' => $this->studentB->id, 'class_id' => $classB->id, 'is_active' => true]);
    }

    public function test_student_can_submit_forgot_password_and_teacher_of_own_class_can_approve(): void
    {
        $this->postJson('/api/v1/auth/forgot-password', ['email' => $this->studentA->email])->assertOk();

        $resetRequest = PasswordResetRequest::query()->where('user_id', $this->studentA->id)->firstOrFail();

        $this->withToken($this->tokenFor($this->teacherB))
            ->getJson('/api/v1/teacher/password-reset-requests')
            ->assertOk()
            ->assertJsonCount(0, 'data');

        $this->withToken($this->tokenFor($this->teacherA))
            ->getJson('/api/v1/teacher/password-reset-requests')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $resetRequest->id);

        $this->withToken($this->tokenFor($this->teacherB))
            ->postJson("/api/v1/teacher/password-reset-requests/{$resetRequest->id}/approve", [
                'password' => 'NewPassword123',
                'password_confirmation' => 'NewPassword123',
            ])->assertForbidden();

        $this->withToken($this->tokenFor($this->teacherA))
            ->postJson("/api/v1/teacher/password-reset-requests/{$resetRequest->id}/approve", [
                'password' => 'NewPassword123',
                'password_confirmation' => 'NewPassword123',
            ])->assertOk()->assertJsonPath('data.status', 'approved');

        $this->studentA->refresh();
        $this->assertTrue(Hash::check('NewPassword123', $this->studentA->password));
        $this->assertTrue($this->studentA->password_must_change);

        $login = $this->postJson('/api/v1/auth/login', [
            'email' => $this->studentA->email,
            'password' => 'NewPassword123',
            'device_name' => 'test',
        ])->assertOk();

        $this->assertTrue($login->json('data.user.password_must_change'));
    }

    public function test_teacher_cannot_approve_own_password_reset_only_admin_can(): void
    {
        $this->postJson('/api/v1/auth/forgot-password', ['email' => $this->teacherA->email])->assertOk();

        $resetRequest = PasswordResetRequest::query()->where('user_id', $this->teacherA->id)->firstOrFail();

        $this->withToken($this->tokenFor($this->teacherA))
            ->getJson('/api/v1/teacher/password-reset-requests')
            ->assertOk()
            ->assertJsonCount(0, 'data');

        $this->withToken($this->tokenFor($this->admin))
            ->postJson("/api/v1/admin/password-reset-requests/{$resetRequest->id}/approve", [
                'password' => 'TeacherNewPass123',
                'password_confirmation' => 'TeacherNewPass123',
            ])->assertOk()->assertJsonPath('data.status', 'approved');

        $this->teacherA->refresh();
        $this->assertTrue(Hash::check('TeacherNewPass123', $this->teacherA->password));
        $this->assertTrue($this->teacherA->password_must_change);
    }

    public function test_admin_forgot_password_does_not_create_approval_request(): void
    {
        $this->postJson('/api/v1/auth/forgot-password', ['email' => $this->admin->email])
            ->assertOk()
            ->assertJsonPath(
                'message',
                'Reset password admin tidak dapat dilakukan lewat email. Minta admin lain untuk mereset password Anda dari menu Guru & Siswa, atau hubungi tim teknis untuk reset via server jika tidak ada admin lain yang bisa login.'
            );

        $this->assertDatabaseMissing('password_reset_requests', ['user_id' => $this->admin->id]);
    }

    public function test_artisan_command_resets_admin_password_when_locked_out(): void
    {
        $this->artisan('admin:reset-password', ['email' => $this->admin->email])
            ->expectsQuestion('Masukkan password baru (minimal 8 karakter, mengandung huruf dan angka)', 'RecoveredPass123')
            ->expectsQuestion('Ulangi password baru', 'RecoveredPass123')
            ->expectsConfirmation("Reset password untuk {$this->admin->email} sekarang? Semua sesi login akun ini akan langsung keluar.", 'yes')
            ->assertExitCode(0);

        $this->admin->refresh();
        $this->assertTrue(Hash::check('RecoveredPass123', $this->admin->password));
        $this->assertTrue($this->admin->password_must_change);
    }

    public function test_artisan_command_rejects_non_admin_target(): void
    {
        $this->artisan('admin:reset-password', ['email' => $this->studentA->email])
            ->assertExitCode(1);

        $this->studentA->refresh();
        $this->assertTrue(Hash::check('OldPassword123', $this->studentA->password));
    }

    public function test_teacher_can_reject_student_reset_request_with_note(): void
    {
        $this->postJson('/api/v1/auth/forgot-password', ['email' => $this->studentA->email])->assertOk();
        $resetRequest = PasswordResetRequest::query()->where('user_id', $this->studentA->id)->firstOrFail();

        $this->withToken($this->tokenFor($this->teacherA))
            ->postJson("/api/v1/teacher/password-reset-requests/{$resetRequest->id}/reject", [])
            ->assertUnprocessable();

        $this->withToken($this->tokenFor($this->teacherA))
            ->postJson("/api/v1/teacher/password-reset-requests/{$resetRequest->id}/reject", [
                'review_note' => 'Bukan siswa yang bersangkutan yang mengajukan.',
            ])->assertOk()->assertJsonPath('data.status', 'rejected');

        $this->assertDatabaseHas('password_reset_requests', ['id' => $resetRequest->id, 'status' => 'rejected']);
    }

    public function test_admin_can_force_reset_password_directly_without_approval(): void
    {
        $this->withToken($this->tokenFor($this->admin))
            ->postJson("/api/v1/users/{$this->studentA->id}/force-password-reset", [
                'password' => 'ForcedPass123',
                'password_confirmation' => 'ForcedPass123',
            ])->assertOk();

        $this->studentA->refresh();
        $this->assertTrue(Hash::check('ForcedPass123', $this->studentA->password));
        $this->assertTrue($this->studentA->password_must_change);

        $this->withToken($this->tokenFor($this->teacherA))
            ->postJson("/api/v1/users/{$this->studentB->id}/force-password-reset", [
                'password' => 'ForcedPass123',
                'password_confirmation' => 'ForcedPass123',
            ])->assertForbidden();
    }

    public function test_duplicate_pending_request_is_rejected(): void
    {
        $this->postJson('/api/v1/auth/forgot-password', ['email' => $this->studentA->email])->assertOk();
        $this->postJson('/api/v1/auth/forgot-password', ['email' => $this->studentA->email])->assertOk();

        $this->assertSame(1, PasswordResetRequest::query()->where('user_id', $this->studentA->id)->count());
    }

    public function test_changing_password_normally_clears_must_change_flag(): void
    {
        $this->studentA->forceFill(['password_must_change' => true])->save();

        $this->withToken($this->tokenFor($this->studentA))
            ->putJson('/api/v1/auth/password', [
                'current_password' => 'OldPassword123',
                'password' => 'BrandNewPass123',
                'password_confirmation' => 'BrandNewPass123',
            ])->assertOk();

        $this->studentA->refresh();
        $this->assertFalse($this->studentA->password_must_change);
    }

    private function tokenFor(User $user): string
    {
        $this->app['auth']->forgetGuards();

        return $user->createToken('PHPUnit')->plainTextToken;
    }
}
