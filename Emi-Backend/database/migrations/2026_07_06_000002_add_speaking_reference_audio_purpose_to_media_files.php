<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement('ALTER TABLE media_files DROP CONSTRAINT media_files_purpose_check');
        DB::statement("ALTER TABLE media_files ADD CONSTRAINT media_files_purpose_check CHECK (purpose IN ('avatar', 'question_image', 'lesson_image', 'culture_media', 'document', 'audio', 'speaking_recording', 'speaking_reference_audio'))");
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE media_files DROP CONSTRAINT media_files_purpose_check');
        DB::statement("ALTER TABLE media_files ADD CONSTRAINT media_files_purpose_check CHECK (purpose IN ('avatar', 'question_image', 'lesson_image', 'culture_media', 'document', 'audio', 'speaking_recording'))");
    }
};
