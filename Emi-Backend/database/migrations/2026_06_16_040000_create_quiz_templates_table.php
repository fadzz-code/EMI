<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('quiz_templates', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('title');
            $table->text('description')->nullable();
            $table->text('instructions')->nullable();
            $table->unsignedInteger('duration_minutes');
            $table->unsignedInteger('max_attempts');
            $table->boolean('show_result')->default(true);
            $table->string('status')->default('draft');
            $table->foreignUuid('created_by')->constrained('users')->restrictOnDelete();
            $table->foreignUuid('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('published_at')->nullable();
            $table->timestamp('archived_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index('title');
            $table->index('status');
            $table->index('created_by');
            $table->index('deleted_at');
        });

        DB::statement("ALTER TABLE quiz_templates ADD CONSTRAINT quiz_templates_status_check CHECK (status IN ('draft', 'published', 'archived'))");
        DB::statement('ALTER TABLE quiz_templates ADD CONSTRAINT quiz_templates_duration_check CHECK (duration_minutes >= 1)');
        DB::statement('ALTER TABLE quiz_templates ADD CONSTRAINT quiz_templates_max_attempts_check CHECK (max_attempts >= 1)');
    }

    public function down(): void
    {
        Schema::dropIfExists('quiz_templates');
    }
};
