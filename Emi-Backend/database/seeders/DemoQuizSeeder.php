<?php

namespace Database\Seeders;

use App\Models\ClassQuiz;
use App\Models\QuizOption;
use App\Models\QuizQuestion;
use App\Models\QuizTemplate;
use App\Models\QuizTemplateOption;
use App\Models\QuizTemplateQuestion;
use App\Models\SchoolClass;
use App\Models\User;
use Illuminate\Database\Seeder;

class DemoQuizSeeder extends Seeder
{
    use DemoSeederSupport;

    public function run(): void
    {
        $admin = User::query()->where('email', 'admin.demo@emi.local')->firstOrFail();
        $teacher = User::query()->where('email', 'guru.rina@emi.local')->firstOrFail();
        $class = SchoolClass::query()->where('name', 'VII-A Mekongga')->firstOrFail();

        foreach ($this->quizzes() as $quizData) {
            $template = $this->upsertModel(QuizTemplate::class, ['title' => $quizData['title']], [
                'description' => $quizData['description'],
                'instructions' => 'Pilih jawaban paling tepat.',
                'duration_minutes' => 30,
                'max_attempts' => 3,
                'show_result' => true,
                'status' => 'published',
                'created_by' => $admin->id,
                'updated_by' => $admin->id,
                'published_at' => now(),
                'archived_at' => null,
            ]);

            $templateQuestions = [];
            foreach ($quizData['questions'] as $index => $question) {
                $templateQuestion = $this->upsertModel(QuizTemplateQuestion::class, ['quiz_template_id' => $template->id, 'order_number' => $index + 1], [
                    'question_type' => 'multiple_choice',
                    'question_text' => $question['question'],
                    'image_media_id' => null,
                    'correct_answer_text' => $question['answer'],
                    'use_fuzzy_matching' => false,
                    'fuzzy_threshold' => null,
                    'points' => 10,
                    'explanation' => $question['explanation'],
                    'created_by' => $admin->id,
                    'updated_by' => $admin->id,
                ]);
                $templateQuestions[] = [$templateQuestion, $question];

                foreach ($question['options'] as $optionIndex => $option) {
                    $this->upsertModel(QuizTemplateOption::class, ['quiz_template_question_id' => $templateQuestion->id, 'order_number' => $optionIndex + 1], [
                        'option_text' => $option,
                        'is_correct' => $option === $question['answer'],
                    ]);
                }
            }

            $classQuiz = $this->upsertModel(ClassQuiz::class, ['class_id' => $class->id, 'source_quiz_template_id' => $template->id], [
                'title' => $template->title,
                'description' => $template->description,
                'instructions' => $template->instructions,
                'duration_minutes' => $template->duration_minutes,
                'max_attempts' => $template->max_attempts,
                'show_result' => true,
                'open_at' => now()->subDay(),
                'close_at' => now()->addMonth(),
                'status' => 'published',
                'created_by' => $teacher->id,
                'updated_by' => $teacher->id,
                'published_at' => now(),
                'archived_at' => null,
            ]);

            foreach ($templateQuestions as [$templateQuestion, $question]) {
                $classQuestion = $this->upsertModel(QuizQuestion::class, ['class_quiz_id' => $classQuiz->id, 'order_number' => $templateQuestion->order_number], [
                    'source_quiz_template_question_id' => $templateQuestion->id,
                    'question_type' => 'multiple_choice',
                    'question_text' => $question['question'],
                    'image_media_id' => null,
                    'correct_answer_text' => $question['answer'],
                    'use_fuzzy_matching' => false,
                    'fuzzy_threshold' => null,
                    'points' => 10,
                    'explanation' => $question['explanation'],
                    'created_by' => $teacher->id,
                    'updated_by' => $teacher->id,
                ]);

                $templateOptions = QuizTemplateOption::query()->where('quiz_template_question_id', $templateQuestion->id)->orderBy('order_number')->get();
                foreach ($templateOptions as $templateOption) {
                    $this->upsertModel(QuizOption::class, ['quiz_question_id' => $classQuestion->id, 'order_number' => $templateOption->order_number], [
                        'source_quiz_template_option_id' => $templateOption->id,
                        'option_text' => $templateOption->option_text,
                        'is_correct' => $templateOption->is_correct,
                    ]);
                }
            }
        }
    }

    private function quizzes(): array
    {
        return [
            ['title' => 'Demo: Kuis Sapaan Dasar', 'description' => 'Kuis demo untuk modul sapaan dasar.', 'questions' => [
                ['question' => 'Apa tujuan mempelajari sapaan dalam bahasa daerah?', 'options' => ['Agar bisa menyapa dengan sopan', 'Agar tidak perlu belajar kosakata', 'Agar hanya menghafal tanpa praktik', 'Agar menghindari percakapan'], 'answer' => 'Agar bisa menyapa dengan sopan', 'explanation' => 'Sapaan membantu memulai percakapan dengan sopan.'],
                ['question' => 'Kosakata demo morini pada rancangan ini digunakan untuk arti apa?', 'options' => ['Terima kasih', 'Selamat tinggal', 'Makan', 'Rumah'], 'answer' => 'Terima kasih', 'explanation' => 'Arti ini perlu validasi narasumber.'],
                ['question' => 'Saat menyapa guru, sikap yang tepat adalah ...', 'options' => ['Sopan dan jelas', 'Berteriak', 'Mengabaikan', 'Bercanda berlebihan'], 'answer' => 'Sopan dan jelas', 'explanation' => 'Bahasa dipakai bersama sikap sopan.'],
            ]],
            ['title' => 'Demo: Kuis Bahasa dan Budaya Mekongga', 'description' => 'Kuis demo untuk modul bahasa dan budaya.', 'questions' => [
                ['question' => 'EMI membantu siswa belajar bahasa Mekongga melalui ...', 'options' => ['Modul, kamus, kuis, speaking, chatbot', 'Hanya membaca daftar nilai', 'Hanya absensi', 'Hanya upload foto'], 'answer' => 'Modul, kamus, kuis, speaking, chatbot', 'explanation' => 'Alur EMI mencakup beberapa fitur belajar.'],
                ['question' => 'Mengapa nilai sopan santun penting dalam belajar bahasa daerah?', 'options' => ['Karena bahasa dipakai sesuai konteks dan lawan bicara', 'Karena membuat kuis lebih sulit', 'Karena mengganti semua materi', 'Karena tidak perlu praktik'], 'answer' => 'Karena bahasa dipakai sesuai konteks dan lawan bicara', 'explanation' => 'Bahasa dan budaya saling terkait.'],
                ['question' => 'Konten budaya di EMI dapat membantu siswa ...', 'options' => ['Mengenal konteks masyarakat dan tradisi', 'Menghapus kamus', 'Menghindari speaking', 'Mengganti profil'], 'answer' => 'Mengenal konteks masyarakat dan tradisi', 'explanation' => 'Budaya memberi konteks penggunaan bahasa.'],
            ]],
        ];
    }
}
