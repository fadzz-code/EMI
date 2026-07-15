<?php

namespace Tests\Feature;

use App\Models\ClassLesson;
use App\Models\ClassModule;
use App\Models\ClassQuiz;
use App\Models\DictionaryCategory;
use App\Models\DictionaryEntry;
use App\Models\ModuleProgress;
use App\Models\ModuleTemplate;
use App\Models\QuizAttempt;
use App\Models\QuizTemplate;
use App\Models\RegistrationRequest;
use App\Models\School;
use App\Models\SchoolClass;
use App\Models\StudentClassMembership;
use App\Models\TeacherClassAssignment;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class Phase8DashboardReportsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-06-16 09:00:00');
        config(['dashboard.export_max_rows' => 100]);
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_admin_dashboard_reports_metrics_scope_period_and_trends(): void
    {
        [$admin, $teacher, $student, $school, $class, $quiz] = $this->seedLearningAndQuizDataset();
        $otherSchool = School::factory()->create(['created_by' => $admin->id]);
        $otherClass = SchoolClass::factory()->create(['school_id' => $otherSchool->id, 'name' => 'Kelas Lain', 'created_by' => $admin->id]);

        $this->withToken($this->tokenFor($teacher))->getJson('/api/v1/admin/dashboard/summary')->assertForbidden();
        $this->withToken($this->tokenFor($student))->getJson('/api/v1/admin/dashboard/summary')->assertForbidden();

        $response = $this->withToken($this->tokenFor($admin))->getJson('/api/v1/admin/dashboard/summary?date_from=2026-06-14&date_to=2026-06-16')
            ->assertOk()
            ->assertJsonPath('data.overview.active_schools', 2)
            ->assertJsonPath('data.overview.active_classes', 2)
            ->assertJsonPath('data.overview.active_teachers', 1)
            ->assertJsonPath('data.overview.active_students', 2)
            ->assertJsonPath('data.overview.pending_registration_requests', 1)
            ->assertJsonPath('data.content.published_module_templates', 1)
            ->assertJsonPath('data.content.published_quiz_templates', 1)
            ->assertJsonPath('data.learning.average_learning_progress_percent', 50)
            ->assertJsonPath('data.quizzes.average_score_percent', 90)
            ->assertJsonPath('data.quizzes.participation_rate_percent', 100)
            ->assertJsonPath('data.capabilities.speaking_reports', false)
            ->assertJsonPath('data.speaking_summary', null);

        $this->assertCount(3, $response->json('data.trends.registrations'));
        $this->assertSame(['date' => '2026-06-15', 'value' => 2], $response->json('data.trends.module_completions.1'));

        $this->withToken($this->tokenFor($admin))->getJson("/api/v1/admin/dashboard/summary?school_id={$school->id}&class_id={$otherClass->id}")
            ->assertUnprocessable()
            ->assertJsonPath('code', 'SCHOOL_CLASS_MISMATCH');

        $schools = $this->withToken($this->tokenFor($admin))->getJson('/api/v1/admin/reports/progress/schools?sort_by=average_learning_progress_percent&sort_direction=desc')
            ->assertOk()
            ->assertJsonPath('data.0.school_name', $school->name);
        $this->assertArrayNotHasKey('password', $schools->json('data.0'));

        $classes = $this->withToken($this->tokenFor($admin))->getJson("/api/v1/admin/reports/progress/classes?school_id={$school->id}")
            ->assertOk()
            ->assertJsonPath('data.0.class_name', $class->name);
        $this->assertSame(2, $classes->json('data.0.active_students'));

        $students = $this->withToken($this->tokenFor($admin))->getJson('/api/v1/admin/reports/progress/students?sort_by=overall_learning_progress_percent&sort_direction=desc')
            ->assertOk();
        $this->assertEquals(100.0, $students->json('data.0.overall_learning_progress_percent'));

        $quizResults = $this->withToken($this->tokenFor($admin))->getJson("/api/v1/admin/reports/quiz-results?quiz_id={$quiz->id}")
            ->assertOk()
            ->assertJsonPath('data.summary.eligible_students', 2)
            ->assertJsonPath('data.summary.participating_students', 2)
            ->assertJsonPath('data.summary.finalized_students', 1)
            ->assertJsonPath('data.summary.average_best_score_percent', 90);
        $this->assertStringNotContainsString('correct_answer_text', $quizResults->getContent());
        $this->assertStringNotContainsString('answer_text', $quizResults->getContent());
    }

    public function test_teacher_and_student_dashboard_scope_hidden_result_and_idor(): void
    {
        [$admin, $teacher, $student, $school, $class, $quiz] = $this->seedLearningAndQuizDataset(showResult: false);
        [$otherClass] = $this->classes($admin, 1, 'Kelas Scope');
        $otherStudent = $this->studentFor($otherClass, $admin);
        $teacherWithoutClass = User::factory()->teacher()->approved()->create();

        $this->withToken($this->tokenFor($student))->getJson('/api/v1/teacher/dashboard/summary')->assertForbidden();
        $this->withToken($this->tokenFor($teacherWithoutClass))->getJson('/api/v1/teacher/dashboard/summary')
            ->assertOk()
            ->assertJsonPath('data.empty_state', true)
            ->assertJsonPath('data.class', null);

        $this->withToken($this->tokenFor($teacher))->getJson('/api/v1/teacher/dashboard/summary')
            ->assertOk()
            ->assertJsonPath('data.class.id', $class->id)
            ->assertJsonPath('data.students.active', 2)
            ->assertJsonPath('data.quizzes.average_score_percent', 90);

        $this->withToken($this->tokenFor($teacher))->getJson("/api/v1/teacher/reports/progress/students?student_id={$otherStudent->id}")
            ->assertForbidden()
            ->assertJsonPath('code', 'REPORT_SCOPE_FORBIDDEN');

        $studentDashboard = $this->withToken($this->tokenFor($student))->getJson('/api/v1/student/dashboard/summary')
            ->assertOk()
            ->assertJsonPath('data.class.id', $class->id)
            ->assertJsonPath('data.learning.overall_progress_percent', 100)
            ->assertJsonPath('data.quizzes.hidden_result_count', 1)
            ->assertJsonPath('data.quizzes.visible_average_score', null);
        $this->assertStringNotContainsString('correct_answer_text', $studentDashboard->getContent());
        $this->assertStringNotContainsString('answer_text', $studentDashboard->getContent());

        $this->withToken($this->tokenFor($student))->getJson("/api/v1/student/reports/progress?student_id={$otherStudent->id}")
            ->assertForbidden()
            ->assertJsonPath('code', 'REPORT_SCOPE_FORBIDDEN');

        $studentQuiz = $this->withToken($this->tokenFor($student))->getJson('/api/v1/student/reports/quiz-results')
            ->assertOk();
        $this->assertNull($studentQuiz->json('data.rows.0.best_score_percent'));
    }

    public function test_admin_report_filters_aggregates_attempt_semantics_and_four_export_parity(): void
    {
        [$admin, , $student, $school, $class, $quiz] = $this->seedLearningAndQuizDataset();
        QuizAttempt::factory()->create([
            'class_quiz_id' => $quiz->id,
            'student_id' => $student->id,
            'attempt_number' => 3,
            'status' => 'submitted',
            'score_percent' => 90,
            'submitted_at' => '2026-06-16 08:00:00',
        ]);

        $token = $this->tokenFor($admin);
        $this->withToken($token)->getJson('/api/v1/admin/reports/progress/students?quiz_status=completed&date_from=2026-06-16&date_to=2026-06-16')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.student_id', $student->id)
            ->assertJsonPath('data.0.quizzes_completed', 1);
        $this->withToken($token)->getJson("/api/v1/admin/reports/quiz-results?quiz_id={$quiz->id}&student_id={$student->id}&date_from=2026-06-16&date_to=2026-06-16")
            ->assertOk()
            ->assertJsonPath('data.rows.0.best_score_percent', 90)
            ->assertJsonPath('data.rows.0.best_attempt_number', 3)
            ->assertJsonPath('data.rows.0.latest_submitted_at', fn ($value) => str_contains($value, '2026-06-16'))
            ->assertJsonPath('data.summary.submitted_attempts', 1);
        $this->withToken($token)->getJson("/api/v1/admin/reports/progress/schools?search={$school->name}&per_page=1")
            ->assertOk()
            ->assertJsonPath('data.0.published_modules', 2)
            ->assertJsonPath('data.0.published_quizzes', 1)
            ->assertJsonPath('meta.per_page', 1);
        $this->withToken($token)->getJson("/api/v1/admin/reports/progress/classes?school_id={$school->id}&search={$class->name}")
            ->assertOk()
            ->assertJsonPath('data.0.class_id', $class->id);

        foreach (['progress/schools', 'progress/classes', 'progress/students', 'quiz-results'] as $report) {
            $response = $this->withToken($token)->get("/api/v1/admin/reports/{$report}/export?date_from=2026-06-16&date_to=2026-06-16")
                ->assertOk();
            $this->assertStringContainsString('attachment;', $response->headers->get('content-disposition'));
            $this->assertStringNotContainsString('password', $response->streamedContent());
        }
    }

    public function test_validation_csv_export_formula_sanitization_and_route_security(): void
    {
        [$admin, $teacher] = $this->seedLearningAndQuizDataset(studentName: '=Formula Student');

        $this->withToken($this->tokenFor($admin))->getJson('/api/v1/admin/dashboard/summary?date_from=2026-06-16&date_to=2026-06-14')
            ->assertUnprocessable()
            ->assertJsonPath('code', 'INVALID_REPORT_PERIOD');

        $this->withToken($this->tokenFor($admin))->getJson('/api/v1/admin/reports/progress/students?sort_by=password')
            ->assertUnprocessable()
            ->assertJsonPath('code', 'VALIDATION_ERROR');

        $this->withToken($this->tokenFor(User::factory()->student()->approved()->create()))->getJson('/api/v1/admin/reports/progress/students/export')
            ->assertForbidden();

        $csv = $this->withToken($this->tokenFor($admin))->get('/api/v1/admin/reports/progress/students/export')
            ->assertOk()
            ->assertHeader('content-type', 'text/csv; charset=UTF-8');
        $this->assertStringContainsString('Nama Siswa', $csv->streamedContent());
        $this->assertStringContainsString("'=Formula Student", $csv->streamedContent());

        $teacherCsv = $this->withToken($this->tokenFor($teacher))->get('/api/v1/teacher/reports/quiz-results/export')
            ->assertOk();
        $this->assertStringContainsString('Nilai Terbaik', $teacherCsv->streamedContent());
    }

    private function seedLearningAndQuizDataset(bool $showResult = true, string $studentName = 'Siswa Satu'): array
    {
        $admin = User::factory()->admin()->create();
        [$class] = $this->classes($admin, 1, 'Kelas Phase 8');
        $school = $class->school;
        $teacher = $this->teacherFor($class, $admin);
        $student = $this->studentFor($class, $admin, $studentName);
        $secondStudent = $this->studentFor($class, $admin, 'Siswa Dua');
        $pending = User::factory()->student()->pending()->create();
        RegistrationRequest::factory()->create(['user_id' => $pending->id, 'school_id' => $school->id, 'class_id' => $class->id, 'status' => 'pending']);
        $category = DictionaryCategory::factory()->create(['created_by' => $admin->id]);
        DictionaryEntry::factory()->create(['category_id' => $category->id, 'created_by' => $admin->id, 'status' => 'active']);
        ModuleTemplate::factory()->published()->create(['created_by' => $admin->id]);
        QuizTemplate::factory()->published()->create(['created_by' => $admin->id]);

        $moduleA = ClassModule::factory()->published()->create(['class_id' => $class->id, 'created_by' => $admin->id, 'sort_order' => 1]);
        $moduleB = ClassModule::factory()->published()->create(['class_id' => $class->id, 'created_by' => $admin->id, 'sort_order' => 2]);
        ClassLesson::factory()->published()->create(['class_module_id' => $moduleA->id, 'created_by' => $admin->id]);
        ClassLesson::factory()->published()->create(['class_module_id' => $moduleB->id, 'created_by' => $admin->id]);
        ModuleProgress::factory()->create([
            'student_id' => $student->id,
            'class_module_id' => $moduleA->id,
            'status' => 'completed',
            'progress_percent' => 100,
            'completed_lessons' => 1,
            'total_lessons' => 1,
            'completed_at' => '2026-06-15 10:00:00',
        ]);
        ModuleProgress::factory()->create([
            'student_id' => $student->id,
            'class_module_id' => $moduleB->id,
            'status' => 'completed',
            'progress_percent' => 100,
            'completed_lessons' => 1,
            'total_lessons' => 1,
            'completed_at' => '2026-06-15 11:00:00',
        ]);

        $quiz = ClassQuiz::factory()->published()->create(['class_id' => $class->id, 'created_by' => $admin->id, 'show_result' => $showResult]);
        QuizAttempt::factory()->create([
            'class_quiz_id' => $quiz->id,
            'student_id' => $student->id,
            'attempt_number' => 1,
            'status' => 'submitted',
            'score_percent' => 70,
            'submitted_at' => '2026-06-15 12:00:00',
        ]);
        QuizAttempt::factory()->create([
            'class_quiz_id' => $quiz->id,
            'student_id' => $student->id,
            'attempt_number' => 2,
            'status' => 'submitted',
            'score_percent' => 90,
            'submitted_at' => '2026-06-15 13:00:00',
        ]);
        QuizAttempt::factory()->create([
            'class_quiz_id' => $quiz->id,
            'student_id' => $secondStudent->id,
            'attempt_number' => 1,
            'status' => 'in_progress',
        ]);

        return [$admin, $teacher, $student, $school, $class, $quiz];
    }

    private function classes(User $admin, int $count, string $prefix): array
    {
        $school = School::factory()->create(['created_by' => $admin->id]);

        return collect(range(1, $count))->map(fn (int $index) => SchoolClass::factory()->create([
            'school_id' => $school->id,
            'name' => "{$prefix} {$index}",
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

    private function studentFor(SchoolClass $class, User $admin, string $name = 'Siswa'): User
    {
        $student = User::factory()->student()->approved()->create(['full_name' => $name]);
        StudentClassMembership::factory()->create(['student_id' => $student->id, 'class_id' => $class->id, 'assigned_by' => $admin->id]);

        return $student;
    }

    private function tokenFor(User $user): string
    {
        $this->app['auth']->forgetGuards();

        return $user->createToken('PHPUnit')->plainTextToken;
    }
}
