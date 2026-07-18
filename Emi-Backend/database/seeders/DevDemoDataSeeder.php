<?php

namespace Database\Seeders;

use App\Models\ClassLesson;
use App\Models\ClassModule;
use App\Models\ClassQuiz;
use App\Models\DictionaryCategory;
use App\Models\DictionaryEntry;
use App\Models\LessonTemplate;
use App\Models\ModuleTemplate;
use App\Models\QuizOption;
use App\Models\QuizQuestion;
use App\Models\QuizTemplate;
use App\Models\QuizTemplateOption;
use App\Models\QuizTemplateQuestion;
use App\Models\School;
use App\Models\SchoolClass;
use App\Models\SpeakingExercise;
use App\Models\StudentClassMembership;
use App\Models\TeacherClassAssignment;
use App\Models\User;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use InvalidArgumentException;

class DevDemoDataSeeder extends Seeder
{
    public function run(): void
    {
        if (! app()->environment('local', 'testing', 'development')) {
            throw new InvalidArgumentException('Seeder demo development hanya boleh dijalankan di environment local, testing, atau development.');
        }

        $this->call(DemoAccountSeeder::class);

        DB::transaction(function (): void {
            $now = now();
            $admin = User::query()->where('email', 'admin@emi.test')->firstOrFail();
            $teacher = User::query()->where('email', 'teacher@emi.test')->firstOrFail();
            $student = User::query()->where('email', 'student@emi.test')->firstOrFail();

            $school = $this->updateOrCreateWithUuid(School::class, ['name' => 'SDN Kolaka'], [
                'address' => 'Kolaka',
                'phone' => null,
                'status' => 'active',
                'created_by' => $admin->id,
            ]);

            $class = $this->updateOrCreateWithUuid(SchoolClass::class, [
                'school_id' => $school->id,
                'name' => 'Kelas 1 A',
                'academic_year' => '2026/2027',
            ], [
                'grade_level' => '1',
                'status' => 'active',
                'created_by' => $admin->id,
            ]);

            $activeTeacherAssignment = TeacherClassAssignment::query()
                ->where('class_id', $class->id)
                ->where('is_active', true)
                ->first();

            TeacherClassAssignment::query()
                ->where('teacher_id', $teacher->id)
                ->where('class_id', '!=', $class->id)
                ->where('is_active', true)
                ->update([
                    'is_active' => false,
                    'ended_at' => $now,
                ]);

            if ($activeTeacherAssignment) {
                $activeTeacherAssignment->update([
                    'teacher_id' => $teacher->id,
                    'assigned_by' => $admin->id,
                    'assigned_at' => $now,
                    'ended_at' => null,
                ]);
            } else {
                $this->updateOrCreateWithUuid(TeacherClassAssignment::class, [
                    'teacher_id' => $teacher->id,
                    'class_id' => $class->id,
                ], [
                    'assigned_by' => $admin->id,
                    'is_active' => true,
                    'assigned_at' => $now,
                    'ended_at' => null,
                ]);
            }

            $this->updateOrCreateWithUuid(StudentClassMembership::class, [
                'student_id' => $student->id,
                'class_id' => $class->id,
            ], [
                'assigned_by' => $admin->id,
                'is_active' => true,
                'joined_at' => $now,
                'ended_at' => null,
            ]);

            $this->seedDictionary($admin);
            $this->call(BasisAiDemoSeeder::class);
            [$moduleTemplate, $lessonTemplates] = $this->seedModuleTemplate($admin, $now);
            $this->seedClassModule($class, $moduleTemplate, $lessonTemplates, $teacher, $now);
            [$quizTemplate, $templateQuestions] = $this->seedQuizTemplate($admin, $now);
            $this->seedClassQuiz($class, $quizTemplate, $templateQuestions, $teacher, $now);
            $this->seedSpeakingExercises($class, $teacher);
        });

        $this->call([
            DemoSchoolClassSeeder::class,
            DemoDictionarySeeder::class,
            DemoKnowledgeSeeder::class,
            DemoLearningSeeder::class,
            DemoQuizSeeder::class,
            DemoSpeakingSeeder::class,
            DemoCultureSeeder::class,
            DemoProgressSeeder::class,
        ]);
    }

    private function seedDictionary(User $admin): void
    {
        $entries = [
            ['Selamat pagi', 'Good morning', 'mompesuka', 'Sapaan'],
            ['Terima kasih', 'Thank you', 'mombesara', 'Sapaan'],
            ['Rumah', 'House', 'laika', 'Benda'],
            ['Air', 'Water', 'Air', 'Benda'],
            ['Makan', 'Eat', 'mekoni', 'Aktivitas'],
            ['Guru', 'Teacher', 'guru', 'Sekolah'],
            ['Siswa', 'Student', 'siswa', 'Sekolah'],
        ];

        foreach (array_unique(array_column($entries, 3)) as $categoryName) {
            $this->updateOrCreateWithUuid(DictionaryCategory::class, ['slug' => Str::slug($categoryName)], [
                'name' => $categoryName,
                'description' => 'Kategori demo '.$categoryName,
                'status' => 'active',
                'created_by' => $admin->id,
                'updated_by' => $admin->id,
            ]);
        }

        foreach ($entries as [$indonesia, $english, $mekongga, $categoryName]) {
            $category = DictionaryCategory::query()->where('slug', Str::slug($categoryName))->firstOrFail();
            $this->updateOrCreateWithUuid(DictionaryEntry::class, [
                'indonesia_normalized' => Str::lower($indonesia),
                'english_normalized' => Str::lower($english),
                'mekongga_normalized' => Str::lower($mekongga),
            ], [
                'category_id' => $category->id,
                'indonesia' => $indonesia,
                'english' => $english,
                'mekongga' => $mekongga,
                'example_mekongga' => null,
                'example_indonesia' => null,
                'audio_media_id' => null,
                'status' => 'active',
                'created_by' => $admin->id,
                'updated_by' => $admin->id,
                'source_import_job_id' => null,
            ]);
        }
    }

    private function seedModuleTemplate(User $admin, mixed $now): array
    {
        $moduleTemplate = $this->updateOrCreateWithUuid(ModuleTemplate::class, ['title' => 'Sapaan Dasar Bahasa Mekongga'], [
            'description' => 'Modul demo untuk mengenal sapaan dasar.',
            'status' => 'published',
            'created_by' => $admin->id,
            'updated_by' => $admin->id,
            'published_at' => $now,
            'archived_at' => null,
        ]);

        $lessons = [
            ['Mengenal Sapaan', 'Belajar sapaan sehari-hari dalam Bahasa Mekongga.', 1],
            ['Memperkenalkan Diri', 'Latihan memperkenalkan nama dan asal.', 2],
            ['Latihan Percakapan Pendek', 'Praktik percakapan sapaan singkat.', 3],
        ];

        $lessonTemplates = [];
        foreach ($lessons as [$title, $body, $order]) {
            $lessonTemplates[] = $this->updateOrCreateWithUuid(LessonTemplate::class, [
                'module_template_id' => $moduleTemplate->id,
                'title' => $title,
            ], [
                'description' => $body,
                'content_type' => 'text',
                'content_body' => $body,
                'media_id' => null,
                'external_url' => null,
                'sort_order' => $order,
                'status' => 'published',
                'created_by' => $admin->id,
                'updated_by' => $admin->id,
                'published_at' => $now,
                'archived_at' => null,
            ]);
        }

        return [$moduleTemplate, $lessonTemplates];
    }

    private function seedClassModule(SchoolClass $class, ModuleTemplate $moduleTemplate, array $lessonTemplates, User $teacher, mixed $now): ClassModule
    {
        $classModule = $this->updateOrCreateWithUuid(ClassModule::class, [
            'class_id' => $class->id,
            'source_module_template_id' => $moduleTemplate->id,
        ], [
            'title' => $moduleTemplate->title,
            'description' => $moduleTemplate->description,
            'status' => 'published',
            'sort_order' => 1,
            'created_by' => $teacher->id,
            'updated_by' => $teacher->id,
            'published_at' => $now,
            'archived_at' => null,
        ]);

        foreach ($lessonTemplates as $lessonTemplate) {
            $this->updateOrCreateWithUuid(ClassLesson::class, [
                'class_module_id' => $classModule->id,
                'source_lesson_template_id' => $lessonTemplate->id,
            ], [
                'title' => $lessonTemplate->title,
                'description' => $lessonTemplate->description,
                'content_type' => $lessonTemplate->content_type,
                'content_body' => $lessonTemplate->content_body,
                'media_id' => null,
                'external_url' => null,
                'sort_order' => $lessonTemplate->sort_order,
                'status' => 'published',
                'created_by' => $teacher->id,
                'updated_by' => $teacher->id,
                'published_at' => $now,
                'archived_at' => null,
            ]);
        }

        return $classModule;
    }

    private function seedQuizTemplate(User $admin, mixed $now): array
    {
        $quizTemplate = $this->updateOrCreateWithUuid(QuizTemplate::class, ['title' => 'Kuis Sapaan Dasar'], [
            'description' => 'Kuis demo sapaan dasar.',
            'instructions' => 'Jawab pertanyaan berikut dengan benar.',
            'duration_minutes' => 30,
            'max_attempts' => 3,
            'show_result' => true,
            'status' => 'published',
            'created_by' => $admin->id,
            'updated_by' => $admin->id,
            'published_at' => $now,
            'archived_at' => null,
        ]);

        $questions = [
            [
                'type' => 'multiple_choice',
                'text' => 'Apa arti "Selamat pagi" dalam Bahasa Inggris?',
                'answer' => 'Good morning',
                'order' => 1,
                'options' => ['Good morning', 'Thank you', 'House', 'Teacher'],
            ],
            [
                'type' => 'multiple_choice',
                'text' => 'Sapaan digunakan untuk apa?',
                'answer' => 'Menyapa orang lain',
                'order' => 2,
                'options' => ['Menyapa orang lain', 'Menghitung angka', 'Membaca buku', 'Menulis alamat'],
            ],
            [
                'type' => 'short_answer',
                'text' => 'Tuliskan satu contoh sapaan yang kamu ketahui.',
                'answer' => 'Selamat pagi',
                'order' => 3,
                'options' => [],
            ],
        ];

        $templateQuestions = [];
        foreach ($questions as $question) {
            $templateQuestion = $this->updateOrCreateWithUuid(QuizTemplateQuestion::class, [
                'quiz_template_id' => $quizTemplate->id,
                'order_number' => $question['order'],
            ], [
                'question_type' => $question['type'],
                'question_text' => $question['text'],
                'image_media_id' => null,
                'correct_answer_text' => $question['answer'],
                'use_fuzzy_matching' => $question['type'] === 'short_answer',
                'fuzzy_threshold' => $question['type'] === 'short_answer' ? 80 : null,
                'points' => 10,
                'explanation' => null,
                'created_by' => $admin->id,
                'updated_by' => $admin->id,
            ]);

            foreach ($question['options'] as $index => $optionText) {
                $this->updateOrCreateWithUuid(QuizTemplateOption::class, [
                    'quiz_template_question_id' => $templateQuestion->id,
                    'order_number' => $index + 1,
                ], [
                    'option_text' => $optionText,
                    'is_correct' => $optionText === $question['answer'],
                ]);
            }

            $templateQuestions[] = $templateQuestion;
        }

        return [$quizTemplate, $templateQuestions];
    }

    private function seedClassQuiz(SchoolClass $class, QuizTemplate $quizTemplate, array $templateQuestions, User $teacher, mixed $now): ClassQuiz
    {
        $classQuiz = $this->updateOrCreateWithUuid(ClassQuiz::class, [
            'class_id' => $class->id,
            'source_quiz_template_id' => $quizTemplate->id,
        ], [
            'title' => $quizTemplate->title,
            'description' => $quizTemplate->description,
            'instructions' => $quizTemplate->instructions,
            'duration_minutes' => $quizTemplate->duration_minutes,
            'max_attempts' => $quizTemplate->max_attempts,
            'show_result' => $quizTemplate->show_result,
            'open_at' => $now->copy()->subDay(),
            'close_at' => $now->copy()->addMonth(),
            'status' => 'published',
            'created_by' => $teacher->id,
            'updated_by' => $teacher->id,
            'published_at' => $now,
            'archived_at' => null,
        ]);

        foreach ($templateQuestions as $templateQuestion) {
            $quizQuestion = $this->updateOrCreateWithUuid(QuizQuestion::class, [
                'class_quiz_id' => $classQuiz->id,
                'order_number' => $templateQuestion->order_number,
            ], [
                'source_quiz_template_question_id' => $templateQuestion->id,
                'question_type' => $templateQuestion->question_type,
                'question_text' => $templateQuestion->question_text,
                'image_media_id' => null,
                'correct_answer_text' => $templateQuestion->correct_answer_text,
                'use_fuzzy_matching' => $templateQuestion->use_fuzzy_matching,
                'fuzzy_threshold' => $templateQuestion->fuzzy_threshold,
                'points' => $templateQuestion->points,
                'explanation' => $templateQuestion->explanation,
                'created_by' => $teacher->id,
                'updated_by' => $teacher->id,
            ]);

            foreach ($templateQuestion->options as $templateOption) {
                $this->updateOrCreateWithUuid(QuizOption::class, [
                    'quiz_question_id' => $quizQuestion->id,
                    'order_number' => $templateOption->order_number,
                ], [
                    'source_quiz_template_option_id' => $templateOption->id,
                    'option_text' => $templateOption->option_text,
                    'is_correct' => $templateOption->is_correct,
                ]);
            }
        }

        return $classQuiz;
    }

    private function seedSpeakingExercises(SchoolClass $class, User $teacher): void
    {
        $exercises = [
            ['Salam dasar', 'Ari nggiro', 'Contoh demo salam sederhana.'],
            ['Perkenalan sederhana', 'Inaku siswa EMI', 'Contoh demo perkenalan sederhana.'],
            ['Kosakata makan', 'Makan', 'Contoh demo kosakata aktivitas.'],
        ];

        foreach ($exercises as [$title, $targetText, $prompt]) {
            $this->updateOrCreateWithUuid(SpeakingExercise::class, [
                'title' => $title,
                'classroom_id' => $class->id,
            ], [
                'prompt_text' => $prompt,
                'target_text' => $targetText,
                'target_translation' => null,
                'language_code' => 'mekongga',
                'difficulty' => 'demo',
                'lesson_id' => null,
                'module_id' => null,
                'created_by_id' => $teacher->id,
                'status' => 'published',
                'metadata' => ['source' => 'demo'],
            ]);
        }
    }

    private function updateOrCreateWithUuid(string $modelClass, array $attributes, array $values)
    {
        $usesSoftDeletes = in_array(SoftDeletes::class, class_uses_recursive($modelClass), true);
        $query = $usesSoftDeletes ? $modelClass::withTrashed() : $modelClass::query();
        $model = $query->where($attributes)->first();

        if (! $model) {
            $model = new $modelClass;
            $model->id = (string) Str::uuid();
            $model->forceFill($attributes);
        }

        if ($usesSoftDeletes && $model->trashed()) {
            $model->restore();
        }

        $model->forceFill($values);
        $model->save();

        return $model;
    }
}
