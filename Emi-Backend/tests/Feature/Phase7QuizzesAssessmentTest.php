<?php

namespace Tests\Feature;

use App\Models\ClassQuiz;
use App\Models\MediaFile;
use App\Models\QuizAttempt;
use App\Models\QuizQuestion;
use App\Models\QuizTemplate;
use App\Models\School;
use App\Models\SchoolClass;
use App\Models\StudentClassMembership;
use App\Models\TeacherClassAssignment;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class Phase7QuizzesAssessmentTest extends TestCase
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
        Carbon::setTestNow('2026-06-16 09:00:00');
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_schema_relationships_and_active_attempt_constraint(): void
    {
        $admin = User::factory()->admin()->create();
        $student = User::factory()->student()->approved()->create();
        $quiz = ClassQuiz::factory()->published()->create(['created_by' => $admin->id]);
        $question = QuizQuestion::factory()->create(['class_quiz_id' => $quiz->id, 'created_by' => $admin->id]);
        $attempt = QuizAttempt::factory()->create(['class_quiz_id' => $quiz->id, 'student_id' => $student->id]);

        $this->assertSame($quiz->id, $question->classQuiz->id);
        $this->assertSame($student->id, $attempt->student->id);

        $this->expectException(QueryException::class);
        QuizAttempt::factory()->create(['class_quiz_id' => $quiz->id, 'student_id' => $student->id, 'status' => 'in_progress']);
    }

    public function test_admin_template_question_validation_publish_lock_apply_and_media_usage(): void
    {
        $admin = User::factory()->admin()->create();
        $teacher = User::factory()->teacher()->approved()->create();
        [$classA, $classB] = $this->classes($admin, 2);
        $questionImage = $this->media($admin, 'question_image', $this->pngFile(), 'public');
        $wrongImage = $this->media($admin, 'lesson_image', $this->pngFile('lesson.png'), 'public');

        $this->withToken($this->tokenFor($teacher))->postJson('/api/v1/admin/quiz-templates', $this->templatePayload())
            ->assertForbidden();

        $templateId = $this->withToken($this->tokenFor($admin))->postJson('/api/v1/admin/quiz-templates', $this->templatePayload())
            ->assertCreated()
            ->assertJsonPath('data.status', 'draft')
            ->json('data.id');

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/quiz-templates/{$templateId}/publish")
            ->assertConflict()
            ->assertJsonPath('code', 'QUIZ_HAS_NO_QUESTIONS');

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/quiz-templates/{$templateId}/questions", $this->multipleChoicePayload([
            'image_media_id' => $wrongImage->id,
        ]))->assertUnprocessable()->assertJsonPath('code', 'INVALID_QUESTION_MEDIA');

        $firstQuestion = $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/quiz-templates/{$templateId}/questions", $this->multipleChoicePayload([
            'image_media_id' => $questionImage->id,
            'order_number' => 1,
        ]))->assertCreated()->json('data.id');

        $secondQuestion = $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/quiz-templates/{$templateId}/questions", $this->shortAnswerPayload([
            'order_number' => 2,
            'correct_answer_text' => 'mekongga',
            'use_fuzzy_matching' => true,
            'fuzzy_threshold' => 80,
        ]))->assertCreated()->json('data.id');

        $this->withToken($this->tokenFor($admin))->patchJson("/api/v1/admin/quiz-templates/{$templateId}/questions/reorder", [
            'question_ids' => [$secondQuestion],
        ])->assertUnprocessable()->assertJsonPath('code', 'INVALID_ORDER');

        $this->withToken($this->tokenFor($admin))->patchJson("/api/v1/admin/quiz-templates/{$templateId}/questions/reorder", [
            'question_ids' => [$secondQuestion, $firstQuestion],
        ])->assertOk();

        $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/quiz-templates/{$templateId}/publish")
            ->assertOk()
            ->assertJsonPath('data.status', 'published');

        $this->withToken($this->tokenFor($admin))->putJson("/api/v1/admin/quiz-template-questions/{$firstQuestion}", [
            'question_text' => 'Terkunci',
        ])->assertConflict()->assertJsonPath('code', 'QUIZ_CONTENT_LOCKED');

        $apply = $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/quiz-templates/{$templateId}/apply", [
            'class_ids' => [$classA->id, $classB->id],
        ])->assertOk();
        $this->assertCount(2, $apply->json('data.applied'));

        $secondApply = $this->withToken($this->tokenFor($admin))->postJson("/api/v1/admin/quiz-templates/{$templateId}/apply", [
            'class_ids' => [$classA->id],
        ])->assertOk();
        $this->assertSame('QUIZ_TEMPLATE_ALREADY_APPLIED', $secondApply->json('data.skipped.0.reason'));

        $template = QuizTemplate::query()->findOrFail($templateId);
        $copy = ClassQuiz::query()->where('class_id', $classA->id)->where('source_quiz_template_id', $template->id)->firstOrFail();
        $template->update(['title' => 'Template Berubah']);
        $this->assertNotSame($template->refresh()->title, $copy->refresh()->title);

        $this->withToken($this->tokenFor($admin))->deleteJson("/api/v1/media/{$questionImage->id}")
            ->assertConflict()
            ->assertJsonPath('code', 'MEDIA_IN_USE');
        $this->assertDatabaseHas('audit_logs', ['action' => 'quiz_template.applied']);
    }

    public function test_class_quiz_student_attempt_grading_idempotency_report_and_visibility(): void
    {
        $admin = User::factory()->admin()->create();
        [$classA, $classB] = $this->classes($admin, 2);
        $teacherA = $this->teacherFor($classA, $admin);
        $teacherB = $this->teacherFor($classB, $admin);
        $studentA = $this->studentFor($classA, $admin);
        $studentB = $this->studentFor($classB, $admin);

        $this->withToken($this->tokenFor($teacherA))->postJson('/api/v1/class-quizzes', $this->classQuizPayload([
            'class_id' => $classB->id,
        ]))->assertForbidden();

        $quizId = $this->withToken($this->tokenFor($teacherA))->postJson('/api/v1/class-quizzes', $this->classQuizPayload([
            'class_id' => $classA->id,
            'show_result' => false,
            'open_at' => '2020-01-01 00:00:00',
            'close_at' => '2099-01-01 00:00:00',
        ]))->assertCreated()->json('data.id');

        $this->withToken($this->tokenFor($teacherB))->putJson("/api/v1/class-quizzes/{$quizId}", ['title' => 'Ambil'])
            ->assertForbidden();

        $mcId = $this->withToken($this->tokenFor($teacherA))->postJson("/api/v1/class-quizzes/{$quizId}/questions", $this->multipleChoicePayload(['order_number' => 1]))
            ->assertCreated()
            ->json('data.id');
        $shortId = $this->withToken($this->tokenFor($teacherA))->postJson("/api/v1/class-quizzes/{$quizId}/questions", $this->shortAnswerPayload([
            'order_number' => 2,
            'correct_answer_text' => 'mekongga',
            'use_fuzzy_matching' => true,
            'fuzzy_threshold' => 80,
        ]))->assertCreated()->json('data.id');
        $mcQuestion = QuizQuestion::query()->with('options')->findOrFail($mcId);
        $correctOption = $mcQuestion->options->firstWhere('is_correct', true);

        $this->withToken($this->tokenFor($teacherA))->postJson("/api/v1/class-quizzes/{$quizId}/publish")->assertOk();

        $this->withToken($this->tokenFor($studentB))->getJson("/api/v1/student/quizzes/{$quizId}")->assertNotFound();
        $studentView = $this->withToken($this->tokenFor($studentA))->getJson("/api/v1/student/quizzes/{$quizId}")->assertOk();
        $studentView->assertJsonMissingPath('data.questions.0.correct_answer_text')
            ->assertJsonMissingPath('data.questions.0.options.0.is_correct');

        $attemptId = $this->withToken($this->tokenFor($studentA))->postJson("/api/v1/class-quizzes/{$quizId}/attempts")
            ->assertCreated()
            ->json('data.id');
        QuizAttempt::query()->whereKey($attemptId)->update(['expires_at' => '2099-01-01 00:00:00']);
        $secondStart = $this->withToken($this->tokenFor($studentA))->postJson("/api/v1/class-quizzes/{$quizId}/attempts")->assertCreated();
        $this->assertSame($attemptId, $secondStart->json('data.id'));

        $this->withToken($this->tokenFor($teacherA))->putJson("/api/v1/class-quizzes/{$quizId}", ['duration_minutes' => 30])
            ->assertConflict()
            ->assertJsonPath('code', 'QUIZ_CONTENT_LOCKED');

        $this->withToken($this->tokenFor($studentA))->putJson("/api/v1/quiz-attempts/{$attemptId}/answers/{$mcId}", [
            'selected_option_id' => $correctOption->id,
        ])->assertOk();
        $this->withToken($this->tokenFor($studentA))->putJson("/api/v1/quiz-attempts/{$attemptId}/answers/{$shortId}", [
            'answer_text' => 'mekonga',
        ])->assertOk();

        $this->withToken($this->tokenFor($studentA))->postJson("/api/v1/quiz-attempts/{$attemptId}/submit")
            ->assertUnprocessable()
            ->assertJsonPath('code', 'VALIDATION_ERROR');

        $key = 'phase7-submit-key-0001';
        $result = $this->withToken($this->tokenFor($studentA))->withHeader('Idempotency-Key', $key)->postJson("/api/v1/quiz-attempts/{$attemptId}/submit")
            ->assertOk()
            ->assertJsonMissingPath('data.score_percent');
        $this->assertSame('submitted', $result->json('data.status'));

        $repeat = $this->withToken($this->tokenFor($studentA))->withHeader('Idempotency-Key', $key)->postJson("/api/v1/quiz-attempts/{$attemptId}/submit")
            ->assertOk();
        $this->assertSame($attemptId, $repeat->json('data.id'));

        $this->withToken($this->tokenFor($studentA))->withHeader('Idempotency-Key', 'phase7-submit-key-0002')->postJson("/api/v1/quiz-attempts/{$attemptId}/submit")
            ->assertConflict()
            ->assertJsonPath('code', 'ATTEMPT_ALREADY_SUBMITTED');

        $attempt = QuizAttempt::query()->findOrFail($attemptId);
        $this->assertSame(100.0, (float) $attempt->score_percent);
        $this->assertNotSame($key, $attempt->submit_idempotency_key_hash);
        $this->assertSame(hash('sha256', $key), $attempt->submit_idempotency_key_hash);

        $report = $this->withToken($this->tokenFor($teacherA))->getJson("/api/v1/class-quizzes/{$quizId}/report")->assertOk();
        $report->assertJsonPath('data.submitted_count', 1)
            ->assertJsonPath('data.average_score_percent', 100);

        $this->withToken($this->tokenFor($studentA))->putJson("/api/v1/quiz-attempts/{$attemptId}/answers/{$mcId}", [
            'selected_option_id' => $correctOption->id,
        ])->assertConflict()->assertJsonPath('code', 'ATTEMPT_ALREADY_SUBMITTED');
    }

    public function test_student_schedule_max_attempt_and_expired_attempt_rules(): void
    {
        $admin = User::factory()->admin()->create();
        [$class] = $this->classes($admin, 1);
        $student = $this->studentFor($class, $admin);

        $future = $this->publishedQuiz($class, $admin, ['open_at' => '2099-01-01 00:00:00', 'close_at' => '2099-01-02 00:00:00']);
        $this->withToken($this->tokenFor($student))->postJson("/api/v1/class-quizzes/{$future->id}/attempts")
            ->assertConflict()
            ->assertJsonPath('code', 'QUIZ_NOT_OPEN');

        $closed = $this->publishedQuiz($class, $admin, ['open_at' => '2020-01-01 00:00:00', 'close_at' => '2020-01-02 00:00:00']);
        $this->withToken($this->tokenFor($student))->postJson("/api/v1/class-quizzes/{$closed->id}/attempts")
            ->assertConflict()
            ->assertJsonPath('code', 'QUIZ_CLOSED');

        $quiz = $this->publishedQuiz($class, $admin, ['max_attempts' => 1, 'duration_minutes' => 1, 'open_at' => '2020-01-01 00:00:00', 'close_at' => '2099-01-01 00:00:00']);
        $attemptId = $this->withToken($this->tokenFor($student))->postJson("/api/v1/class-quizzes/{$quiz->id}/attempts")->assertCreated()->json('data.id');
        QuizAttempt::query()->whereKey($attemptId)->update(['expires_at' => '2020-01-01 00:00:00']);
        $questionId = $quiz->questions()->firstOrFail()->id;
        $this->withToken($this->tokenFor($student))->putJson("/api/v1/quiz-attempts/{$attemptId}/answers/{$questionId}", [
            'answer_text' => 'mekongga',
        ])->assertConflict()->assertJsonPath('code', 'ATTEMPT_EXPIRED');
        $this->withToken($this->tokenFor($student))->postJson("/api/v1/class-quizzes/{$quiz->id}/attempts")
            ->assertConflict()
            ->assertJsonPath('code', 'QUIZ_MAX_ATTEMPTS_REACHED');
    }

    private function publishedQuiz(SchoolClass $class, User $admin, array $attributes = []): ClassQuiz
    {
        $quiz = ClassQuiz::factory()->published()->create(array_merge([
            'class_id' => $class->id,
            'created_by' => $admin->id,
            'open_at' => '2020-01-01 00:00:00',
            'close_at' => '2099-01-01 00:00:00',
        ], $attributes));
        QuizQuestion::factory()->create([
            'class_quiz_id' => $quiz->id,
            'created_by' => $admin->id,
            'question_text' => 'Apa nama kerajaan lokal?',
            'correct_answer_text' => 'mekongga',
        ]);

        return $quiz;
    }

    private function templatePayload(array $overrides = []): array
    {
        return array_merge([
            'title' => 'Kuis Mekongga',
            'description' => 'Kuis dasar',
            'instructions' => 'Jawab semua soal.',
            'duration_minutes' => 20,
            'max_attempts' => 2,
            'show_result' => true,
        ], $overrides);
    }

    private function classQuizPayload(array $overrides = []): array
    {
        return array_merge($this->templatePayload(), $overrides);
    }

    private function multipleChoicePayload(array $overrides = []): array
    {
        return array_merge([
            'question_type' => 'multiple_choice',
            'question_text' => 'Apa arti kata ini?',
            'points' => 5,
            'order_number' => 1,
            'options' => [
                ['option_text' => 'Benar', 'is_correct' => true, 'order_number' => 1],
                ['option_text' => 'Salah', 'is_correct' => false, 'order_number' => 2],
            ],
        ], $overrides);
    }

    private function shortAnswerPayload(array $overrides = []): array
    {
        return array_merge([
            'question_type' => 'short_answer',
            'question_text' => 'Tuliskan jawabannya.',
            'correct_answer_text' => 'mekongga',
            'use_fuzzy_matching' => false,
            'points' => 5,
            'order_number' => 1,
        ], $overrides);
    }

    private function classes(User $admin, int $count): array
    {
        $school = School::factory()->create(['created_by' => $admin->id]);

        return collect(range(1, $count))->map(fn (int $index) => SchoolClass::factory()->create([
            'school_id' => $school->id,
            'name' => "Kelas Phase 7 {$index}",
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

    private function pngFile(string $name = 'question.png'): UploadedFile
    {
        return UploadedFile::fake()->createWithContent($name, base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII='));
    }
}
