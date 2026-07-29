<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('chatbot_conversations', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('title')->nullable();
            $table->string('status')->default('active');
            $table->timestamp('last_message_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index('user_id');
            $table->index('status');
            $table->index('last_message_at');
            $table->index(['user_id', 'status', 'last_message_at']);
        });

        DB::statement("ALTER TABLE chatbot_conversations ADD CONSTRAINT chatbot_conversations_status_check CHECK (status IN ('active', 'archived'))");
    }

    public function down(): void
    {
        Schema::dropIfExists('chatbot_conversations');
    }
};
