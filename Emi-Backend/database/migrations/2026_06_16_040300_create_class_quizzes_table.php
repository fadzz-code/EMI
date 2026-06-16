<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('class_quizzes', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('class_id')->constrained('classes')->restrictOnDelete();
            $table->foreignUuid('source_quiz_template_id')->nullable()->constrained('quiz_templates')->nullOnDelete();
            $table->string('title');
            $table->text('description')->nullable();
            $table->text('instructions')->nullable();
            $table->unsignedInteger('duration_minutes');
            $table->unsignedInteger('max_attempts');
            $table->boolean('show_result')->default(true);
            $table->timestampTz('open_at')->nullable();
            $table->timestampTz('close_at')->nullable();
            $table->string('status')->default('draft');
            $table->foreignUuid('created_by')->constrained('users')->restrictOnDelete();
            $table->foreignUuid('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('published_at')->nullable();
            $table->timestamp('archived_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index('class_id');
            $table->index('source_quiz_template_id');
            $table->index('status');
            $table->index('open_at');
            $table->index('close_at');
            $table->index('deleted_at');
        });

        DB::statement("ALTER TABLE class_quizzes ADD CONSTRAINT class_quizzes_status_check CHECK (status IN ('draft', 'published', 'archived'))");
        DB::statement('ALTER TABLE class_quizzes ADD CONSTRAINT class_quizzes_duration_check CHECK (duration_minutes >= 1)');
        DB::statement('ALTER TABLE class_quizzes ADD CONSTRAINT class_quizzes_max_attempts_check CHECK (max_attempts >= 1)');
        DB::statement('ALTER TABLE class_quizzes ADD CONSTRAINT class_quizzes_schedule_check CHECK (open_at IS NULL OR close_at IS NULL OR open_at < close_at)');
        DB::statement('CREATE UNIQUE INDEX unique_active_class_quiz_template ON class_quizzes (class_id, source_quiz_template_id) WHERE source_quiz_template_id IS NOT NULL AND deleted_at IS NULL');
    }

    public function down(): void
    {
        Schema::dropIfExists('class_quizzes');
    }
};
