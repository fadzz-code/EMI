<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('speaking_exercises', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('title');
            $table->text('prompt_text')->nullable();
            $table->text('target_text');
            $table->text('target_translation')->nullable();
            $table->string('language_code')->default('mekongga');
            $table->string('difficulty')->nullable();
            $table->foreignUuid('lesson_id')->nullable()->constrained('class_lessons')->nullOnDelete();
            $table->foreignUuid('module_id')->nullable()->constrained('class_modules')->nullOnDelete();
            $table->foreignUuid('classroom_id')->nullable()->constrained('classes')->nullOnDelete();
            $table->foreignUuid('created_by_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('status')->default('draft');
            $table->json('metadata')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['status', 'classroom_id']);
        });

        Schema::create('speaking_attempts', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('speaking_exercise_id')->constrained()->cascadeOnDelete();
            $table->foreignUuid('student_id')->constrained('users')->cascadeOnDelete();
            $table->foreignUuid('audio_media_id')->nullable()->constrained('media_files')->nullOnDelete();
            $table->string('audio_path')->nullable();
            $table->string('audio_disk')->nullable();
            $table->string('audio_mime_type')->nullable();
            $table->unsignedBigInteger('audio_size_bytes')->nullable();
            $table->unsignedInteger('audio_duration_seconds')->nullable();
            $table->text('target_text_snapshot');
            $table->string('status')->default('pending');
            $table->string('ai_engine')->nullable();
            $table->string('ai_model')->nullable();
            $table->text('ai_transcription')->nullable();
            $table->decimal('ai_score', 5, 2)->nullable();
            $table->json('ai_alignment')->nullable();
            $table->json('ai_raw_response')->nullable();
            $table->text('ai_error')->nullable();
            $table->decimal('teacher_score', 5, 2)->nullable();
            $table->text('teacher_feedback')->nullable();
            $table->foreignUuid('reviewed_by_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reviewed_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['student_id', 'status']);
            $table->index('speaking_exercise_id');
        });

        DB::statement("ALTER TABLE speaking_exercises ADD CONSTRAINT speaking_exercises_status_check CHECK (status IN ('draft', 'published'))");
        DB::statement("ALTER TABLE speaking_attempts ADD CONSTRAINT speaking_attempts_status_check CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'reviewed'))");
    }

    public function down(): void
    {
        Schema::dropIfExists('speaking_attempts');
        Schema::dropIfExists('speaking_exercises');
    }
};
