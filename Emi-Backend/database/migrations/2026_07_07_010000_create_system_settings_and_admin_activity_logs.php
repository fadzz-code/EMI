<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement('ALTER TABLE media_files DROP CONSTRAINT media_files_purpose_check');
        DB::statement("ALTER TABLE media_files ADD CONSTRAINT media_files_purpose_check CHECK (purpose IN ('avatar', 'question_image', 'lesson_image', 'culture_media', 'document', 'audio', 'speaking_recording', 'speaking_reference_audio', 'login_banner'))");

        Schema::create('system_settings', function (Blueprint $table) {
            $table->string('key')->primary();
            $table->json('value')->nullable();
            $table->timestamps();
        });

        Schema::create('admin_activity_logs', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('admin_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('action');
            $table->string('title')->nullable();
            $table->json('properties')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('admin_activity_logs');
        Schema::dropIfExists('system_settings');
        DB::statement('ALTER TABLE media_files DROP CONSTRAINT media_files_purpose_check');
        DB::statement("ALTER TABLE media_files ADD CONSTRAINT media_files_purpose_check CHECK (purpose IN ('avatar', 'question_image', 'lesson_image', 'culture_media', 'document', 'audio', 'speaking_recording', 'speaking_reference_audio'))");
    }
};
