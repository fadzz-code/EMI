<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('quiz_answers', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('quiz_attempt_id')->constrained('quiz_attempts')->cascadeOnDelete();
            $table->foreignUuid('quiz_question_id')->constrained('quiz_questions')->restrictOnDelete();
            $table->foreignUuid('selected_option_id')->nullable()->constrained('quiz_options')->nullOnDelete();
            $table->text('answer_text')->nullable();
            $table->text('normalized_answer')->nullable();
            $table->boolean('is_correct')->nullable();
            $table->decimal('similarity_score', 5, 2)->nullable();
            $table->decimal('awarded_points', 10, 2)->default(0);
            $table->decimal('max_points', 10, 2);
            $table->timestampTz('answered_at')->nullable();
            $table->timestamps();

            $table->unique(['quiz_attempt_id', 'quiz_question_id']);
            $table->index('quiz_attempt_id');
            $table->index('quiz_question_id');
        });

        DB::statement('ALTER TABLE quiz_answers ADD CONSTRAINT quiz_answers_similarity_check CHECK (similarity_score IS NULL OR similarity_score BETWEEN 0 AND 100)');
        DB::statement('ALTER TABLE quiz_answers ADD CONSTRAINT quiz_answers_points_check CHECK (awarded_points >= 0 AND max_points >= 0)');
        DB::statement('ALTER TABLE quiz_answers ADD CONSTRAINT quiz_answers_payload_check CHECK (selected_option_id IS NULL OR answer_text IS NULL)');
    }

    public function down(): void
    {
        Schema::dropIfExists('quiz_answers');
    }
};
