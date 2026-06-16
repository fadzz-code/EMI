<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('class_lessons', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('class_module_id')->constrained('class_modules')->cascadeOnDelete();
            $table->foreignUuid('source_lesson_template_id')->nullable()->constrained('lesson_templates')->nullOnDelete();
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('content_type');
            $table->text('content_body')->nullable();
            $table->foreignUuid('media_id')->nullable()->constrained('media_files')->nullOnDelete();
            $table->string('external_url')->nullable();
            $table->unsignedInteger('sort_order')->default(1);
            $table->string('status')->default('draft');
            $table->foreignUuid('created_by')->constrained('users')->restrictOnDelete();
            $table->foreignUuid('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('published_at')->nullable();
            $table->timestamp('archived_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index('class_module_id');
            $table->index('source_lesson_template_id');
            $table->index('media_id');
            $table->index('status');
            $table->index('sort_order');
            $table->index('deleted_at');
        });

        DB::statement("ALTER TABLE class_lessons ADD CONSTRAINT class_lessons_status_check CHECK (status IN ('draft', 'published', 'archived'))");
        DB::statement("ALTER TABLE class_lessons ADD CONSTRAINT class_lessons_content_type_check CHECK (content_type IN ('text', 'image', 'audio', 'pdf', 'video', 'link'))");
    }

    public function down(): void
    {
        Schema::dropIfExists('class_lessons');
    }
};
