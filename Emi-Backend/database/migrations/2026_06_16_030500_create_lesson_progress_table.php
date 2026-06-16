<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('lesson_progress', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('student_id')->constrained('users')->restrictOnDelete();
            $table->foreignUuid('class_lesson_id')->constrained('class_lessons')->restrictOnDelete();
            $table->string('status')->default('not_started');
            $table->unsignedTinyInteger('progress_percent')->default(0);
            $table->timestamp('started_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('last_accessed_at')->nullable();
            $table->timestamps();

            $table->unique(['student_id', 'class_lesson_id']);
            $table->index('student_id');
            $table->index('class_lesson_id');
            $table->index('status');
        });

        DB::statement("ALTER TABLE lesson_progress ADD CONSTRAINT lesson_progress_status_check CHECK (status IN ('not_started', 'in_progress', 'completed'))");
        DB::statement('ALTER TABLE lesson_progress ADD CONSTRAINT lesson_progress_percent_check CHECK (progress_percent BETWEEN 0 AND 100)');
    }

    public function down(): void
    {
        Schema::dropIfExists('lesson_progress');
    }
};
