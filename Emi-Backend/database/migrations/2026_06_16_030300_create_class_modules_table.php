<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('class_modules', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('class_id')->constrained('classes')->restrictOnDelete();
            $table->foreignUuid('source_module_template_id')->nullable()->constrained('module_templates')->nullOnDelete();
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('status')->default('draft');
            $table->unsignedInteger('sort_order')->default(1);
            $table->foreignUuid('created_by')->constrained('users')->restrictOnDelete();
            $table->foreignUuid('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('published_at')->nullable();
            $table->timestamp('archived_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index('class_id');
            $table->index('source_module_template_id');
            $table->index('status');
            $table->index('sort_order');
            $table->index('deleted_at');
        });

        DB::statement("ALTER TABLE class_modules ADD CONSTRAINT class_modules_status_check CHECK (status IN ('draft', 'published', 'archived'))");
        DB::statement('CREATE UNIQUE INDEX unique_active_class_module_template ON class_modules (class_id, source_module_template_id) WHERE source_module_template_id IS NOT NULL AND deleted_at IS NULL');
    }

    public function down(): void
    {
        Schema::dropIfExists('class_modules');
    }
};
