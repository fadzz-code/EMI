<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_knowledge_source_pages', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('ai_knowledge_item_id')->constrained()->cascadeOnDelete();
            $table->unsignedInteger('page_number');
            $table->longText('content');
            $table->string('content_hash');
            $table->unsignedInteger('char_count');
            $table->unsignedInteger('word_count');
            $table->json('metadata')->nullable();
            $table->timestamps();

            $table->index('ai_knowledge_item_id');
            $table->index('page_number');
            $table->index('content_hash');
            $table->unique(['ai_knowledge_item_id', 'page_number']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_knowledge_source_pages');
    }
};
