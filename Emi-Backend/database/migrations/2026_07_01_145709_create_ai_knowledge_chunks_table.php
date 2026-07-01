<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_knowledge_chunks', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('ai_knowledge_item_id')->constrained()->cascadeOnDelete();
            $table->unsignedInteger('chunk_index');
            $table->text('content');
            $table->string('content_hash')->nullable();
            $table->unsignedInteger('character_count');
            $table->unsignedInteger('token_estimate')->nullable();
            $table->json('metadata')->nullable();
            $table->timestamps();

            $table->unique(['ai_knowledge_item_id', 'chunk_index']);
            $table->index('content_hash');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_knowledge_chunks');
    }
};
