<?php

namespace Tests\Feature;

use App\Models\RegistrationRequest;
use App\Models\School;
use App\Models\SchoolClass;
use App\Models\StudentClassMembership;
use App\Models\TeacherClassAssignment;
use App\Models\User;
use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Password;
use Tests\TestCase;

class Phase2AuthApprovalTest extends TestCase
{
    use RefreshDatabase;

    public function test_public_school_lookup_only_returns_active_schools(): void
    {
        $activeSchool = School::factory()->create(['name' => 'SMP Aktif']);
        School::factory()->inactive()->create(['name' => 'SMP Nonaktif']);

        $response = $this->getJson('/api/v1/public/schools');

        $response
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.0.id', $activeSchool->id);

        $this->assertCount(1, $response->json('data'));
    }

    public function test_public_class_lookup_only_returns_active_classes_from_selected_school(): void
    {
        $school = School::factory()->create();
        $otherSchool = School::factory()->create();
        $activeClass = SchoolClass::factory()->create(['school_id' => $school->id, 'name' => 'Kelas 7A']);
        SchoolClass::factory()->inactive()->create(['school_id' => $school->id, 'name' => 'Kelas 7B']);
        SchoolClass::factory()->create(['school_id' => $otherSchool->id, 'name' => 'Kelas Sekolah Lain']);

        $response = $this->getJson("/api/v1/public/schools/{$school->id}/classes");

        $response
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.0.id', $activeClass->id);

        $this->assertCount(1, $response->json('data'));
    }

    public function test_public_class_lookup_requires_active_school(): void
    {
        $school = School::factory()->inactive()->create();

        $this->getJson("/api/v1/public/schools/{$school->id}/classes")
            ->assertNotFound()
            ->assertJsonPath('success', false)
            ->assertJsonPath('code', 'NOT_FOUND');
    }

    public function test_student_can_register_and_receives_no_token(): void
    {
        [$school, $schoolClass] = $this->activeSchoolAndClass();

        $response = $this->postJson('/api/v1/auth/register', $this->registerPayload([
            'email' => 'Siswa@Example.test',
            'requested_role' => 'student',
            'school_id' => $school->id,
            'class_id' => $schoolClass->id,
        ]));

        $response
            ->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonMissingPath('data.token')
            ->assertJsonPath('data.status', 'pending');

        $user = User::query()->where('email', 'siswa@example.test')->firstOrFail();

        $this->assertSame('student', $user->role);
        $this->assertSame('pending', $user->status);
        $this->assertTrue(Hash::check('Password123', $user->password));
        $this->assertDatabaseHas('registration_requests', [
            'user_id' => $user->id,
            'school_id' => $school->id,
            'class_id' => $schoolClass->id,
            'requested_role' => 'student',
            'status' => 'pending',
        ]);
    }

    public function test_teacher_can_register_as_pending(): void
    {
        [$school, $schoolClass] = $this->activeSchoolAndClass();

        $response = $this->postJson('/api/v1/auth/register', $this->registerPayload([
            'email' => 'guru@example.test',
            'requested_role' => 'teacher',
            'school_id' => $school->id,
            'class_id' => $schoolClass->id,
        ]));

        $response->assertCreated()->assertJsonPath('data.status', 'pending');

        $this->assertDatabaseHas('users', [
            'email' => 'guru@example.test',
            'role' => 'teacher',
            'status' => 'pending',
        ]);
    }

    public function test_registration_rejects_invalid_role_duplicate_email_inactive_targets_and_mismatched_class(): void
    {
        [$school, $schoolClass] = $this->activeSchoolAndClass();
        $inactiveSchool = School::factory()->inactive()->create();
        $inactiveClass = SchoolClass::factory()->inactive()->create(['school_id' => $school->id]);
        $otherClass = SchoolClass::factory()->create();
        User::factory()->create(['email' => 'duplikat@example.test']);

        $this->postJson('/api/v1/auth/register', $this->registerPayload([
            'requested_role' => 'admin',
            'school_id' => $school->id,
            'class_id' => $schoolClass->id,
        ]))->assertUnprocessable();

        $this->postJson('/api/v1/auth/register', $this->registerPayload([
            'email' => 'duplikat@example.test',
            'school_id' => $school->id,
            'class_id' => $schoolClass->id,
        ]))->assertUnprocessable();

        $this->postJson('/api/v1/auth/register', $this->registerPayload([
            'school_id' => $inactiveSchool->id,
            'class_id' => $schoolClass->id,
        ]))->assertUnprocessable();

        $this->postJson('/api/v1/auth/register', $this->registerPayload([
            'school_id' => $school->id,
            'class_id' => $inactiveClass->id,
        ]))->assertUnprocessable();

        $this->postJson('/api/v1/auth/register', $this->registerPayload([
            'school_id' => $school->id,
            'class_id' => $otherClass->id,
        ]))->assertUnprocessable();
    }

    public function test_approved_user_can_login_and_last_login_is_updated(): void
    {
        $user = User::factory()->student()->approved()->create([
            'email' => 'login@example.test',
            'password' => 'Password123',
            'last_login_at' => null,
        ]);

        $response = $this->postJson('/api/v1/auth/login', [
            'email' => 'login@example.test',
            'password' => 'Password123',
            'device_name' => 'PHPUnit',
        ]);

        $response
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.token_type', 'Bearer')
            ->assertJsonPath('data.user.id', $user->id);

        $this->assertNotNull($response->json('data.token'));
        $this->assertDatabaseHas('personal_access_tokens', ['tokenable_id' => $user->id]);
        $this->assertNotNull($user->refresh()->last_login_at);
    }

    public function test_login_rejects_pending_rejected_inactive_and_wrong_password(): void
    {
        foreach (['pending', 'rejected', 'inactive'] as $status) {
            User::factory()->student()->state([
                'email' => "{$status}@example.test",
                'password' => 'Password123',
                'status' => $status,
            ])->create();

            $this->postJson('/api/v1/auth/login', [
                'email' => "{$status}@example.test",
                'password' => 'Password123',
                'device_name' => 'PHPUnit',
            ])->assertForbidden()->assertJsonPath('code', 'ACCOUNT_NOT_APPROVED');
        }

        User::factory()->student()->approved()->create([
            'email' => 'wrong-password@example.test',
            'password' => 'Password123',
        ]);

        $this->postJson('/api/v1/auth/login', [
            'email' => 'wrong-password@example.test',
            'password' => 'Salah123',
            'device_name' => 'PHPUnit',
        ])->assertUnauthorized()->assertJsonPath('code', 'INVALID_CREDENTIALS');
    }

    public function test_profile_requires_token_and_returns_active_student_class(): void
    {
        $this->getJson('/api/v1/auth/me')
            ->assertUnauthorized()
            ->assertJsonPath('code', 'UNAUTHENTICATED');

        $student = User::factory()->student()->approved()->create();
        [$school, $schoolClass] = $this->activeSchoolAndClass();
        StudentClassMembership::factory()->create([
            'student_id' => $student->id,
            'class_id' => $schoolClass->id,
        ]);

        $this->withToken($this->tokenFor($student))
            ->getJson('/api/v1/auth/me')
            ->assertOk()
            ->assertJsonPath('data.id', $student->id)
            ->assertJsonPath('data.active_school.id', $school->id)
            ->assertJsonPath('data.active_class.id', $schoolClass->id);
    }

    public function test_profile_only_updates_allowed_fields(): void
    {
        $student = User::factory()->student()->approved()->create(['full_name' => 'Nama Lama']);
        $schoolClass = SchoolClass::factory()->create();
        StudentClassMembership::factory()->create([
            'student_id' => $student->id,
            'class_id' => $schoolClass->id,
        ]);

        $this->withToken($this->tokenFor($student))->patchJson('/api/v1/auth/me', [
            'full_name' => 'Nama Baru',
            'phone' => '081234567890',
            'role' => 'admin',
            'status' => 'inactive',
            'class_id' => SchoolClass::factory()->create()->id,
        ])->assertOk()->assertJsonPath('data.full_name', 'Nama Baru');

        $student->refresh();

        $this->assertSame('student', $student->role);
        $this->assertSame('approved', $student->status);
        $this->assertSame('081234567890', $student->phone);
        $this->assertSame($schoolClass->id, $student->activeStudentClassMembership->class_id);
    }

    public function test_password_update_requires_current_password_hashes_new_password_and_keeps_current_token_active(): void
    {
        $user = User::factory()->student()->approved()->create(['password' => 'Password123']);
        $token = $this->tokenFor($user);

        $this->withToken($token)->putJson('/api/v1/auth/password', [
            'current_password' => 'Salah123',
            'password' => 'PasswordBaru123',
            'password_confirmation' => 'PasswordBaru123',
        ])->assertUnprocessable()->assertJsonPath('code', 'INVALID_CURRENT_PASSWORD');

        $this->withToken($token)->putJson('/api/v1/auth/password', [
            'current_password' => 'Password123',
            'password' => 'PasswordBaru123',
            'password_confirmation' => 'PasswordBaru123',
        ])->assertOk();

        $this->assertTrue(Hash::check('PasswordBaru123', $user->refresh()->password));
        $this->withToken($token)->getJson('/api/v1/auth/me')->assertOk();
    }

    public function test_account_delete_requires_password_deactivates_user_and_revokes_tokens(): void
    {
        $student = User::factory()->student()->approved()->create(['password' => 'Password123']);
        $schoolClass = SchoolClass::factory()->create();
        StudentClassMembership::factory()->create([
            'student_id' => $student->id,
            'class_id' => $schoolClass->id,
        ]);
        $token = $this->tokenFor($student);

        $this->withToken($token)->deleteJson('/api/v1/auth/account', [
            'current_password' => 'Salah123',
        ])->assertUnprocessable()->assertJsonPath('code', 'INVALID_CURRENT_PASSWORD');

        $this->withToken($token)->deleteJson('/api/v1/auth/account', [
            'current_password' => 'Password123',
        ])->assertOk();

        $this->assertSame('inactive', $student->refresh()->status);
        $this->assertDatabaseHas('student_class_memberships', [
            'student_id' => $student->id,
            'is_active' => false,
        ]);
        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_last_admin_cannot_delete_own_account(): void
    {
        $admin = User::factory()->admin()->approved()->create(['password' => 'Password123']);

        $this->withToken($this->tokenFor($admin))->deleteJson('/api/v1/auth/account', [
            'current_password' => 'Password123',
        ])->assertConflict()->assertJsonPath('code', 'LAST_ADMIN_ACCOUNT');
    }

    public function test_forgot_password_uses_safe_response_and_sends_reset_notification(): void
    {
        Notification::fake();
        $user = User::factory()->student()->approved()->create(['email' => 'reset@example.test']);

        $this->postJson('/api/v1/auth/forgot-password', [
            'email' => 'reset@example.test',
        ])->assertOk()->assertJsonPath('message', 'Jika email terdaftar, petunjuk akan dikirim.');

        $this->postJson('/api/v1/auth/forgot-password', [
            'email' => 'missing@example.test',
        ])->assertOk()->assertJsonPath('message', 'Jika email terdaftar, petunjuk akan dikirim.');

        Notification::assertSentTo($user, ResetPassword::class);
    }

    public function test_reset_password_changes_password_and_revokes_tokens(): void
    {
        $user = User::factory()->student()->approved()->create([
            'email' => 'reset@example.test',
            'password' => 'Password123',
        ]);
        $token = Password::broker()->createToken($user);
        $accessToken = $this->tokenFor($user);

        $this->postJson('/api/v1/auth/reset-password', [
            'email' => 'reset@example.test',
            'token' => $token,
            'password' => 'PasswordBaru123',
            'password_confirmation' => 'PasswordBaru123',
        ])->assertOk()->assertJsonPath('message', 'Kata sandi berhasil diubah.');

        $this->assertTrue(Hash::check('PasswordBaru123', $user->refresh()->password));
        $this->withToken($accessToken)->getJson('/api/v1/auth/me')->assertUnauthorized();
    }

    public function test_logout_revokes_current_token(): void
    {
        $user = User::factory()->student()->approved()->create();
        $token = $this->tokenFor($user);

        $this->withToken($token)->postJson('/api/v1/auth/logout')->assertOk();
        $this->assertDatabaseCount('personal_access_tokens', 0);

        $this->refreshApplication();

        $this->withToken($token)->getJson('/api/v1/auth/me')->assertUnauthorized();
    }

    public function test_non_admin_cannot_access_registration_requests(): void
    {
        $teacher = User::factory()->teacher()->approved()->create();

        $this->withToken($this->tokenFor($teacher))
            ->getJson('/api/v1/admin/registration-requests')
            ->assertForbidden()
            ->assertJsonPath('code', 'FORBIDDEN');
    }

    public function test_admin_can_list_search_filter_show_registration_requests_without_sensitive_fields(): void
    {
        $admin = User::factory()->admin()->create();
        $registrationRequest = $this->pendingRegistrationRequest('student', ['full_name' => 'Siti Kolaka', 'email' => 'siti@example.test']);
        $teacherRequest = $this->pendingRegistrationRequest('teacher', ['full_name' => 'Guru Mekongga', 'email' => 'guru-mekongga@example.test']);

        $response = $this->withToken($this->tokenFor($admin))
            ->getJson('/api/v1/admin/registration-requests?status=pending&requested_role=student&search=siti&per_page=1')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.0.id', $registrationRequest->id)
            ->assertJsonPath('data.0.requested_role', 'student')
            ->assertJsonPath('meta.per_page', 1)
            ->assertJsonMissingPath('data.0.user.password')
            ->assertJsonMissingPath('data.0.user.remember_token');

        $this->assertCount(1, $response->json('data'));

        $this->withToken($this->tokenFor($admin))
            ->getJson('/api/v1/admin/registration-requests?requested_role=teacher&search=guru-mekongga')
            ->assertOk()
            ->assertJsonPath('data.0.id', $teacherRequest->id);

        $this->withToken($this->tokenFor($admin))
            ->getJson("/api/v1/admin/registration-requests/{$registrationRequest->id}")
            ->assertOk()
            ->assertJsonPath('data.id', $registrationRequest->id)
            ->assertJsonPath('data.user.id', $registrationRequest->user_id)
            ->assertJsonMissingPath('data.user.password');
    }

    public function test_admin_can_approve_student_and_create_active_membership_only(): void
    {
        $admin = User::factory()->admin()->create();
        $registrationRequest = $this->pendingRegistrationRequest('student');

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/admin/registration-requests/{$registrationRequest->id}/approve", [
                'review_note' => 'Data telah diverifikasi.',
            ])
            ->assertOk()
            ->assertJsonPath('data.status', 'approved');

        $this->assertDatabaseHas('users', [
            'id' => $registrationRequest->user_id,
            'status' => 'approved',
            'approved_by' => $admin->id,
        ]);
        $this->assertDatabaseHas('student_class_memberships', [
            'student_id' => $registrationRequest->user_id,
            'class_id' => $registrationRequest->class_id,
            'is_active' => true,
        ]);
        $this->assertDatabaseMissing('teacher_class_assignments', [
            'teacher_id' => $registrationRequest->user_id,
        ]);
    }

    public function test_admin_can_approve_teacher_and_create_active_assignment_only(): void
    {
        $admin = User::factory()->admin()->create();
        $registrationRequest = $this->pendingRegistrationRequest('teacher');

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/admin/registration-requests/{$registrationRequest->id}/approve")
            ->assertOk()
            ->assertJsonPath('data.status', 'approved');

        $this->assertDatabaseHas('teacher_class_assignments', [
            'teacher_id' => $registrationRequest->user_id,
            'class_id' => $registrationRequest->class_id,
            'is_active' => true,
        ]);
        $this->assertDatabaseMissing('student_class_memberships', [
            'student_id' => $registrationRequest->user_id,
        ]);
    }

    public function test_teacher_approval_conflicts_when_class_already_has_active_teacher(): void
    {
        $admin = User::factory()->admin()->create();
        $registrationRequest = $this->pendingRegistrationRequest('teacher');
        TeacherClassAssignment::factory()->create([
            'class_id' => $registrationRequest->class_id,
            'assigned_by' => $admin->id,
        ]);

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/admin/registration-requests/{$registrationRequest->id}/approve")
            ->assertConflict()
            ->assertJsonPath('code', 'CLASS_ALREADY_HAS_TEACHER');
    }

    public function test_registration_request_cannot_be_processed_twice(): void
    {
        $admin = User::factory()->admin()->create();
        $registrationRequest = $this->pendingRegistrationRequest('student');

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/admin/registration-requests/{$registrationRequest->id}/approve")
            ->assertOk();

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/admin/registration-requests/{$registrationRequest->id}/approve")
            ->assertConflict()
            ->assertJsonPath('code', 'REGISTRATION_ALREADY_PROCESSED');
    }

    public function test_admin_can_reject_request_and_no_assignment_or_membership_is_created(): void
    {
        $admin = User::factory()->admin()->create();
        $registrationRequest = $this->pendingRegistrationRequest('student');

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/admin/registration-requests/{$registrationRequest->id}/reject")
            ->assertUnprocessable();

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/admin/registration-requests/{$registrationRequest->id}/reject", [
                'review_note' => 'Data sekolah tidak sesuai.',
            ])
            ->assertOk()
            ->assertJsonPath('data.status', 'rejected');

        $this->assertDatabaseHas('users', [
            'id' => $registrationRequest->user_id,
            'status' => 'rejected',
            'rejected_reason' => 'Data sekolah tidak sesuai.',
        ]);
        $this->assertDatabaseMissing('student_class_memberships', ['student_id' => $registrationRequest->user_id]);
        $this->assertDatabaseMissing('teacher_class_assignments', ['teacher_id' => $registrationRequest->user_id]);

        $this->withToken($this->tokenFor($admin))
            ->postJson("/api/v1/admin/registration-requests/{$registrationRequest->id}/approve")
            ->assertConflict()
            ->assertJsonPath('code', 'REGISTRATION_ALREADY_PROCESSED');
    }

    public function test_login_and_registration_rate_limits_are_applied(): void
    {
        User::factory()->student()->approved()->create([
            'email' => 'ratelimit-login@example.test',
            'password' => 'Password123',
        ]);

        for ($i = 0; $i < 5; $i++) {
            $this->withServerVariables(['REMOTE_ADDR' => '10.10.10.10'])->postJson('/api/v1/auth/login', [
                'email' => 'ratelimit-login@example.test',
                'password' => 'Salah123',
                'device_name' => 'PHPUnit',
            ])->assertUnauthorized();
        }

        $this->withServerVariables(['REMOTE_ADDR' => '10.10.10.10'])->postJson('/api/v1/auth/login', [
            'email' => 'ratelimit-login@example.test',
            'password' => 'Salah123',
            'device_name' => 'PHPUnit',
        ])->assertStatus(429);

        [$school, $schoolClass] = $this->activeSchoolAndClass();
        for ($i = 0; $i < 10; $i++) {
            $this->withServerVariables(['REMOTE_ADDR' => '10.10.10.11'])->postJson('/api/v1/auth/register', $this->registerPayload([
                'email' => "rate-register-{$i}@example.test",
                'school_id' => $school->id,
                'class_id' => $schoolClass->id,
            ]))->assertCreated();
        }

        $this->withServerVariables(['REMOTE_ADDR' => '10.10.10.11'])->postJson('/api/v1/auth/register', $this->registerPayload([
            'email' => 'rate-register-10@example.test',
            'school_id' => $school->id,
            'class_id' => $schoolClass->id,
        ]))->assertStatus(429);
    }

    public function test_error_response_uses_standard_shape(): void
    {
        $this->postJson('/api/v1/auth/register', [])
            ->assertUnprocessable()
            ->assertJsonStructure(['success', 'message', 'code', 'errors'])
            ->assertJsonPath('success', false)
            ->assertJsonPath('code', 'VALIDATION_ERROR');
    }

    private function activeSchoolAndClass(): array
    {
        $school = School::factory()->create();
        $schoolClass = SchoolClass::factory()->create(['school_id' => $school->id]);

        return [$school, $schoolClass];
    }

    private function registerPayload(array $overrides = []): array
    {
        return array_merge([
            'full_name' => 'Andi Pratama',
            'email' => 'andi@example.test',
            'password' => 'Password123',
            'password_confirmation' => 'Password123',
            'requested_role' => 'student',
            'school_id' => null,
            'class_id' => null,
        ], $overrides);
    }

    private function tokenFor(User $user): string
    {
        return $user->createToken('PHPUnit')->plainTextToken;
    }

    private function pendingRegistrationRequest(string $role, array $userOverrides = []): RegistrationRequest
    {
        [$school, $schoolClass] = $this->activeSchoolAndClass();
        $user = User::factory()->{$role}()->pending()->create($userOverrides);

        return RegistrationRequest::factory()->create([
            'user_id' => $user->id,
            'school_id' => $school->id,
            'class_id' => $schoolClass->id,
            'requested_role' => $role,
            'status' => 'pending',
        ]);
    }
}
