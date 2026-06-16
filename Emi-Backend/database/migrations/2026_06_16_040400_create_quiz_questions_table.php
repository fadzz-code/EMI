<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('quiz_questions', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('class_quiz_id')->constrained('class_quizzes')->cascadeOnDelete();
            $table->foreignUuid('source_quiz_template_question_id')->nullable()->constrained('quiz_template_questions')->nullOnDelete();
            $table->string('question_type');
            $table->text('question_text');
            $table->foreignUuid('image_media_id')->nullable()->constrained('media_files')->nullOnDelete();
            $table->text('correct_answer_text')->nullable();
            $table->boolean('use_fuzzy_matching')->default(false);
            $table->unsignedTinyInteger('fuzzy_threshold')->nullable();
            $table->unsignedInteger('points');
            $table->unsignedInteger('order_number');
            $table->text('explanation')->nullable();
            $table->foreignUuid('created_by')->constrained('users')->restrictOnDelete();
            $table->foreignUuid('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->softDeletes();

            $table->index('class_quiz_id');
            $table->index('source_quiz_template_question_id');
            $table->index('image_media_id');
            $table->index('order_number');
            $table->index('deleted_at');
        });

        DB::statement("ALTER TABLE quiz_questions ADD CONSTRAINT quiz_questions_type_check CHECK (question_type IN ('multiple_choice', 'short_answer'))");
        DB::statement('ALTER TABLE quiz_questions ADD CONSTRAINT quiz_questions_points_check CHECK (points > 0)');
        DB::statement('ALTER TABLE quiz_questions ADD CONSTRAINT quiz_questions_order_check CHECK (order_number > 0)');
        DB::statement('ALTER TABLE quiz_questions ADD CONSTRAINT quiz_questions_fuzzy_check CHECK (fuzzy_threshold IS NULL OR fuzzy_threshold BETWEEN 1 AND 100)');
        DB::statement('CREATE UNIQUE INDEX unique_active_quiz_question_order ON quiz_questions (class_quiz_id, order_number) WHERE deleted_at IS NULL');
    }

    public function down(): void
    {
        Schema::dropIfExists('quiz_questions');
    }
};
