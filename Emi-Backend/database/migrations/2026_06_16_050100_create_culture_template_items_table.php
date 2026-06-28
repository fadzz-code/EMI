<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('culture_template_items', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('culture_template_id')->constrained('culture_templates')->cascadeOnDelete();
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
            $table->index(['culture_template_id', 'status']);
        });

        DB::statement("ALTER TABLE culture_template_items ADD CONSTRAINT culture_template_items_status_check CHECK (status IN ('draft', 'published', 'archived'))");
        DB::statement("ALTER TABLE culture_template_items ADD CONSTRAINT culture_template_items_content_type_check CHECK (content_type IN ('image', 'audio', 'pdf', 'video', 'youtube', 'article', 'link'))");
    }

    public function down(): void
    {
        Schema::dropIfExists('culture_template_items');
    }
};
