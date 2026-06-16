<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('quiz_attempts', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('class_quiz_id')->constrained('class_quizzes')->restrictOnDelete();
            $table->foreignUuid('student_id')->constrained('users')->restrictOnDelete();
            $table->unsignedInteger('attempt_number');
            $table->string('status')->default('in_progress');
            $table->timestampTz('started_at');
            $table->timestampTz('expires_at');
            $table->timestampTz('submitted_at')->nullable();
            $table->decimal('score_points', 10, 2)->default(0);
            $table->decimal('max_points', 10, 2)->default(0);
            $table->decimal('score_percent', 5, 2)->default(0);
            $table->unsignedInteger('correct_count')->default(0);
            $table->unsignedInteger('incorrect_count')->default(0);
            $table->unsignedInteger('unanswered_count')->default(0);
            $table->string('submit_idempotency_key_hash', 64)->nullable();
            $table->timestamps();

            $table->unique(['class_quiz_id', 'student_id', 'attempt_number']);
            $table->index('class_quiz_id');
            $table->index('student_id');
            $table->index('status');
            $table->index('submitted_at');
        });

        DB::statement("ALTER TABLE quiz_attempts ADD CONSTRAINT quiz_attempts_status_check CHECK (status IN ('in_progress', 'submitted', 'expired'))");
        DB::statement('ALTER TABLE quiz_attempts ADD CONSTRAINT quiz_attempts_number_check CHECK (attempt_number > 0)');
        DB::statement('ALTER TABLE quiz_attempts ADD CONSTRAINT quiz_attempts_score_check CHECK (score_points >= 0 AND max_points >= 0 AND score_percent BETWEEN 0 AND 100)');
        DB::statement("CREATE UNIQUE INDEX unique_active_quiz_attempt ON quiz_attempts (class_quiz_id, student_id) WHERE status = 'in_progress'");
    }

    public function down(): void
    {
        Schema::dropIfExists('quiz_attempts');
    }
};
