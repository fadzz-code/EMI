<?php

namespace Tests\Feature;

use App\Models\ClassModule;
use App\Models\ClassQuiz;
use App\Models\ModuleProgress;
use App\Models\QuizAttempt;
use App\Models\School;
use App\Models\SchoolClass;
use App\Models\StudentClassMembership;
use App\Models\TeacherClassAssignment;
use App\Models\User;
use App\Services\SimplePdfService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Smalot\PdfParser\Parser;
use Tests\TestCase;

class AdminProgressDetailPdfTest extends TestCase
{
    use RefreshDatabase;

    public function test_overview_summary_capability_combined_search_and_shared_filters(): void
    {
        [$admin, , $student, $school, $class] = $this->dataset();
        $url = '/api/v1/admin/reports/progress/overview';

        $this->admin($admin)->getJson($url)->assertOk()
            ->assertJsonPath('data.summary.active_students', 2)
            ->assertJsonPath('data.summary.average_module_progress_percent', 50)
            ->assertJsonPath('data.summary.average_best_final_quiz_score_percent', 90)
            ->assertJsonPath('data.capabilities.speaking_reports', false);
        $this->admin($admin)->getJson($url.'?search='.urlencode($student->full_name))->assertJsonCount(1, 'data.students.data')->assertJsonCount(1, 'data.classes.data');
        $this->admin($admin)->getJson($url.'?search='.urlencode($class->name))->assertJsonCount(2, 'data.students.data')->assertJsonCount(1, 'data.classes.data');
        $this->admin($admin)->getJson("{$url}?school_id={$school->id}&class_id={$class->id}&learning_status=completed&quiz_status=completed")
            ->assertOk()->assertJsonCount(1, 'data.students.data')->assertJsonPath('data.students.data.0.student_id', $student->id);
    }

    public function test_overview_has_independent_student_and_class_pagination(): void
    {
        [$admin, , , $school] = $this->dataset();
        $otherClass = SchoolClass::factory()->create(['school_id' => $school->id, 'created_by' => $admin->id, 'name' => 'Kelas Kedua']);
        $this->student($otherClass, $admin, 'Siswa Ketiga');

        $this->admin($admin)->getJson('/api/v1/admin/reports/progress/overview?student_page=2&student_per_page=1&class_page=1&class_per_page=1')
            ->assertOk()->assertJsonPath('data.students.meta.current_page', 2)->assertJsonPath('data.students.meta.per_page', 1)
            ->assertJsonPath('data.classes.meta.current_page', 1)->assertJsonPath('data.classes.meta.per_page', 1);
    }

    public function test_student_detail_has_safe_identity_progress_and_paginated_best_final_quiz_summary(): void
    {
        [$admin, , $student, , $class] = $this->dataset();
        ClassQuiz::factory()->published()->create(['class_id' => $class->id, 'created_by' => $admin->id]);

        $response = $this->admin($admin)->getJson("/api/v1/admin/reports/progress/students/{$student->id}?quiz_page=2&quiz_per_page=1")
            ->assertOk()->assertJsonPath('data.student.id', $student->id)->assertJsonPath('data.student.status', 'approved')
            ->assertJsonPath('data.student.email', $student->email)->assertJsonPath('data.progress.overall_learning_progress_percent', 100)
            ->assertJsonPath('data.quizzes.meta.current_page', 2)->assertJsonPath('data.quizzes.meta.per_page', 1)
            ->assertJsonPath('data.quiz_summary.average_best_score_percent', 90)->assertJsonPath('data.capabilities.speaking_reports', false);
        $this->assertStringNotContainsString('password', $response->getContent());
        $this->assertStringNotContainsString('answer_text', $response->getContent());
    }

    public function test_class_detail_has_identity_teacher_true_summary_and_student_pagination(): void
    {
        [$admin, $teacher, , $school, $class] = $this->dataset();

        $this->admin($admin)->getJson("/api/v1/admin/reports/progress/classes/{$class->id}?page=2&per_page=1")
            ->assertOk()->assertJsonPath('data.class.school.id', $school->id)->assertJsonPath('data.class.academic_year', $class->academic_year)
            ->assertJsonPath('data.class.teacher.id', $teacher->id)->assertJsonPath('data.summary.active_students', 2)
            ->assertJsonPath('data.summary.average_module_progress_percent', 50)->assertJsonPath('data.summary.average_best_final_quiz_score_percent', 90)
            ->assertJsonPath('data.summary.completed_students', 1)->assertJsonPath('data.summary.not_started_students', 1)
            ->assertJsonPath('data.summary.last_activity_at', fn ($value) => str_contains($value, now('UTC')->toDateString()))
            ->assertJsonPath('data.capabilities.speaking_reports', false)->assertJsonPath('data.students.meta.current_page', 2);
    }

    public function test_global_student_and_class_pdfs_have_safe_headers_names_content_and_audit(): void
    {
        [$admin, , $student, , $class] = $this->dataset();
        $paths = [
            '/api/v1/admin/reports/progress/pdf' => ['laporan-progress-siswa.pdf', ['Laporan Progress Siswa', 'Filter Laporan', 'Ringkasan', 'Tabel Progress Siswa', 'Siswa Utama', 'Speaking', 'Dicetak dari Admin EMI']],
            "/api/v1/admin/reports/progress/students/{$student->id}/pdf" => ['progress-siswa-siswa-utama.pdf', ['Identitas Siswa', 'Ringkasan Progress', 'Riwayat Kuis', '90%', 'Speaking', 'Dicetak dari Admin EMI']],
            "/api/v1/admin/reports/progress/classes/{$class->id}/pdf" => ['progress-kelas-kelas-laporan.pdf', ['Laporan Progress Kelas', 'Identitas Kelas', 'Ringkasan Progress Kelas', 'Tabel Siswa', 'Siswa Utama', 'Speaking', 'Dicetak dari Admin EMI']],
        ];

        foreach ($paths as $path => [$filename, $contents]) {
            $response = $this->admin($admin)->get($path)->assertOk()->assertHeader('content-type', 'application/pdf');
            $this->assertStringContainsString('no-store', $response->headers->get('cache-control'));
            $this->assertStringContainsString('private', $response->headers->get('cache-control'));
            $this->assertStringStartsWith('%PDF-', $response->getContent());
            $this->assertStringContainsString($filename, $response->headers->get('content-disposition'));
            $pdf = (new Parser)->parseContent($response->getContent());
            $text = $pdf->getText();
            $this->assertGreaterThanOrEqual(1, count($pdf->getPages()));
            foreach ($contents as $content) {
                $this->assertStringContainsString($content, $text);
            }
            $this->assertStringNotContainsString($student->id, $text);
            $this->assertStringNotContainsString('not_started', $text);
            $this->assertStringNotContainsString('password', $text);
            $this->assertStringNotContainsString('answer_text', $text);
        }
        $this->assertDatabaseCount('audit_logs', 3);
    }

    public function test_pdf_renderer_repeats_table_headers_without_blank_pages(): void
    {
        $rows = array_fill(0, 100, ['Siswa panjang untuk menguji pergantian halaman', 'Selesai']);
        $content = app(SimplePdfService::class)->make(['title' => 'Laporan Banyak Halaman', 'sections' => [['title' => 'Tabel Siswa', 'headers' => ['Nama siswa', 'Status belajar'], 'rows' => $rows, 'widths' => [350, 161]]]]);
        $pdf = (new Parser)->parseContent($content);

        $this->assertGreaterThan(1, count($pdf->getPages()));
        foreach ($pdf->getPages() as $page) {
            $text = trim($page->getText());
            $this->assertNotSame('', $text);
            $this->assertStringContainsString('Nama siswa', $text);
            $this->assertStringContainsString('Status belajar', $text);
        }
    }

    public function test_pdf_routes_deny_teacher_student_and_guest(): void
    {
        [$admin, $teacher, $student] = $this->dataset();
        $path = '/api/v1/admin/reports/progress/pdf';

        $this->getJson($path)->assertUnauthorized();
        $this->admin($teacher)->get($path)->assertForbidden();
        $this->admin($student)->get($path)->assertForbidden();
    }

    public function test_detail_rejects_contradictory_identity_query_and_csv_is_private(): void
    {
        [$admin, , $student] = $this->dataset();
        $other = User::factory()->student()->approved()->create();

        $this->admin($admin)->getJson("/api/v1/admin/reports/progress/students/{$student->id}?student_id={$other->id}")->assertUnprocessable();
        $response = $this->admin($admin)->get('/api/v1/admin/reports/progress/students/export')->assertOk();
        $this->assertStringContainsString('no-store', $response->headers->get('cache-control'));
        $this->assertStringContainsString('private', $response->headers->get('cache-control'));
    }

    public function test_period_validation_applies_to_overview_details_and_pdfs(): void
    {
        [$admin, , $student, , $class] = $this->dataset();
        foreach (['/api/v1/admin/reports/progress/overview', "/api/v1/admin/reports/progress/students/{$student->id}", "/api/v1/admin/reports/progress/classes/{$class->id}", '/api/v1/admin/reports/progress/pdf'] as $path) {
            $this->admin($admin)->getJson($path.'?date_from=2026-06-16&date_to=2026-06-14')->assertUnprocessable()->assertJsonPath('code', 'INVALID_REPORT_PERIOD');
        }
    }

    private function dataset(): array
    {
        $admin = User::factory()->admin()->create();
        $school = School::factory()->create(['created_by' => $admin->id]);
        $class = SchoolClass::factory()->create(['school_id' => $school->id, 'created_by' => $admin->id, 'name' => 'Kelas Laporan', 'academic_year' => '2026/2027']);
        $teacher = User::factory()->teacher()->approved()->create();
        TeacherClassAssignment::factory()->create(['teacher_id' => $teacher->id, 'class_id' => $class->id, 'assigned_by' => $admin->id]);
        $student = $this->student($class, $admin, 'Siswa Utama');
        $this->student($class, $admin, 'Siswa Kosong');
        $module = ClassModule::factory()->published()->create(['class_id' => $class->id, 'created_by' => $admin->id]);
        ModuleProgress::factory()->create(['student_id' => $student->id, 'class_module_id' => $module->id, 'status' => 'completed', 'progress_percent' => 100, 'completed_at' => now('UTC')->setTime(10, 0), 'last_calculated_at' => now('UTC')->setTime(10, 0), 'created_at' => now('UTC')->setTime(10, 0), 'updated_at' => now('UTC')->setTime(10, 0)]);
        $quiz = ClassQuiz::factory()->published()->create(['class_id' => $class->id, 'created_by' => $admin->id]);
        QuizAttempt::factory()->create(['class_quiz_id' => $quiz->id, 'student_id' => $student->id, 'attempt_number' => 1, 'status' => 'submitted', 'score_percent' => 70, 'submitted_at' => now('UTC')->setTime(12, 0)]);
        QuizAttempt::factory()->create(['class_quiz_id' => $quiz->id, 'student_id' => $student->id, 'attempt_number' => 2, 'status' => 'submitted', 'score_percent' => 90, 'submitted_at' => now('UTC')->setTime(13, 0)]);

        return [$admin, $teacher, $student, $school, $class];
    }

    private function student(SchoolClass $class, User $admin, string $name): User
    {
        $student = User::factory()->student()->approved()->create(['full_name' => $name]);
        StudentClassMembership::factory()->create(['student_id' => $student->id, 'class_id' => $class->id, 'assigned_by' => $admin->id]);

        return $student;
    }

    private function admin(User $user): static
    {
        $this->app['auth']->forgetGuards();

        return $this->withToken($user->createToken('PHPUnit')->plainTextToken);
    }
}
