<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_knowledge_items', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('title');
            $table->string('category')->nullable();
            $table->text('content');
            $table->string('source_type');
            $table->string('source_url')->nullable();
            $table->string('status')->default('draft');
            $table->foreignUuid('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignUuid('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->softDeletes();

            $table->index('title');
            $table->index('category');
            $table->index('source_type');
            $table->index('status');
            $table->index('created_by');
            $table->index('deleted_at');
        });

        DB::statement("ALTER TABLE ai_knowledge_items ADD CONSTRAINT ai_knowledge_items_source_type_check CHECK (source_type IN ('manual', 'link', 'pdf'))");
        DB::statement("ALTER TABLE ai_knowledge_items ADD CONSTRAINT ai_knowledge_items_status_check CHECK (status IN ('draft', 'published', 'archived'))");
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_knowledge_items');
    }
};
