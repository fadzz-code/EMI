<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('class_culture_items', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('class_id')->constrained('classes')->cascadeOnDelete();
            $table->foreignUuid('source_culture_template_id')->nullable()->constrained('culture_templates')->nullOnDelete();
            $table->foreignUuid('source_culture_template_item_id')->nullable()->constrained('culture_template_items')->nullOnDelete();
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('content_type');
            $table->foreignUuid('media_id')->nullable()->constrained('media_files')->nullOnDelete();
            $table->string('external_url', 2048)->nullable();
            $table->foreignUuid('thumbnail_media_id')->nullable()->constrained('media_files')->nullOnDelete();
            $table->unsignedInteger('display_order')->default(1);
            $table->string('status')->default('draft');
            $table->foreignUuid('created_by')->constrained('users')->restrictOnDelete();
            $table->foreignUuid('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('published_at')->nullable();
            $table->timestamp('archived_at')->nullable();
            $table->timestamps();
            $table->softDeletes();
            $table->index(['class_id', 'status']);
            $table->unique(['class_id', 'source_culture_template_item_id'], 'class_culture_source_item_unique');
        });

        DB::statement("ALTER TABLE class_culture_items ADD CONSTRAINT class_culture_items_status_check CHECK (status IN ('draft', 'published', 'archived'))");
        DB::statement("ALTER TABLE class_culture_items ADD CONSTRAINT class_culture_items_content_type_check CHECK (content_type IN ('image', 'audio', 'pdf', 'video', 'youtube', 'article', 'link'))");
    }

    public function down(): void
    {
        Schema::dropIfExists('class_culture_items');
    }
};
