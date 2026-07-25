<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('chatbot_messages', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('chatbot_conversation_id')->constrained()->cascadeOnDelete();
            $table->string('role');
            $table->text('content');
            $table->json('citations')->nullable();
            $table->string('retrieval_mode')->nullable();
            $table->string('provider')->nullable();
            $table->unsignedTinyInteger('confidence')->nullable();
            $table->string('fallback_reason')->nullable();
            $table->timestamps();

            $table->index('chatbot_conversation_id');
            $table->index(['chatbot_conversation_id', 'created_at']);
        });

        DB::statement("ALTER TABLE chatbot_messages ADD CONSTRAINT chatbot_messages_role_check CHECK (role IN ('user', 'assistant'))");
    }

    public function down(): void
    {
        Schema::dropIfExists('chatbot_messages');
    }
};
