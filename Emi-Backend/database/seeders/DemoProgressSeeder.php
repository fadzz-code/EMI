<?php

namespace Database\Seeders;

use App\Models\ClassLesson;
use App\Models\ClassModule;
use App\Models\ClassQuiz;
use App\Models\LessonProgress;
use App\Models\ModuleProgress;
use App\Models\QuizAttempt;
use App\Models\SpeakingAttempt;
use App\Models\SpeakingExercise;
use App\Models\User;
use Illuminate\Database\Seeder;

class DemoProgressSeeder extends Seeder
{
    use DemoSeederSupport;

    public function run(): void
    {
        $mira = User::query()->where('email', 'siswa.mira@emi.local')->firstOrFail();
        $rafi = User::query()->where('email', 'siswa.rafi@emi.local')->firstOrFail();
        $teacher = User::query()->where('email', 'guru.rina@emi.local')->firstOrFail();
        $module = ClassModule::query()->where('title', 'Demo: Sapaan Dasar Bahasa Mekongga')->first();
        $quiz = ClassQuiz::query()->where('title', 'Demo: Kuis Sapaan Dasar')->first();
        $exercise = SpeakingExercise::query()->where('title', 'Demo Target: Sapaan kepada Guru')->first();

        if ($module) {
            $lessons = ClassLesson::query()->where('class_module_id', $module->id)->orderBy('sort_order')->get();
            $this->moduleProgress($mira, $module, 'in_progress', 33, 1, $lessons->count());
            $this->moduleProgress($rafi, $module, 'completed', 100, $lessons->count(), $lessons->count());

            foreach ($lessons as $index => $lesson) {
                if ($index === 0) {
                    $this->lessonProgress($mira, $lesson, 'completed', 100);
                }
                $this->lessonProgress($rafi, $lesson, 'completed', 100);
            }
        }

        if ($quiz) {
            $this->upsertModel(QuizAttempt::class, ['class_quiz_id' => $quiz->id, 'student_id' => $rafi->id, 'attempt_number' => 1], [
                'status' => 'submitted',
                'started_at' => now()->subDays(2),
                'expires_at' => now()->subDays(2)->addMinutes($quiz->duration_minutes),
                'submitted_at' => now()->subDays(2)->addMinutes(12),
                'score_points' => 30,
                'max_points' => 30,
                'score_percent' => 100,
                'correct_count' => 3,
                'incorrect_count' => 0,
                'unanswered_count' => 0,
                'submit_idempotency_key_hash' => hash('sha256', 'demo-rafi-quiz-1'),
            ]);
        }

        if ($exercise) {
            $this->upsertModel(SpeakingAttempt::class, ['speaking_exercise_id' => $exercise->id, 'student_id' => $rafi->id], [
                'audio_media_id' => null,
                'audio_path' => null,
                'audio_disk' => null,
                'audio_mime_type' => null,
                'audio_size_bytes' => null,
                'audio_duration_seconds' => null,
                'target_text_snapshot' => $exercise->target_text,
                'status' => 'completed',
                'analysis_status' => 'completed',
                'review_status' => 'reviewed',
                'ai_engine' => 'demo',
                'ai_model' => 'demo-rubric',
                'ai_transcription' => $exercise->target_text,
                'ai_score' => 88,
                'ai_alignment' => ['demo' => true],
                'ai_raw_response' => ['message' => 'Demo speaking attempt.'],
                'ai_error' => null,
                'teacher_score' => 90,
                'teacher_feedback' => 'Pengucapan demo sudah jelas. Konten bahasa perlu validasi narasumber.',
                'reviewed_by_id' => $teacher->id,
                'reviewed_at' => now()->subDay(),
            ]);
        }
    }

    private function moduleProgress(User $student, ClassModule $module, string $status, int $percent, int $completed, int $total): void
    {
        $this->upsertModel(ModuleProgress::class, ['student_id' => $student->id, 'class_module_id' => $module->id], [
            'status' => $status,
            'progress_percent' => $percent,
            'completed_lessons' => $completed,
            'total_lessons' => $total,
            'started_at' => now()->subDays(3),
            'completed_at' => $status === 'completed' ? now()->subDay() : null,
            'last_calculated_at' => now(),
        ]);
    }

    private function lessonProgress(User $student, ClassLesson $lesson, string $status, int $percent): void
    {
        $this->upsertModel(LessonProgress::class, ['student_id' => $student->id, 'class_lesson_id' => $lesson->id], [
            'status' => $status,
            'progress_percent' => $percent,
            'started_at' => now()->subDays(3),
            'completed_at' => $status === 'completed' ? now()->subDay() : null,
            'last_accessed_at' => now(),
        ]);
    }
}
