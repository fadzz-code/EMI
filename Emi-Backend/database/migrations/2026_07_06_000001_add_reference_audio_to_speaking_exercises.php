<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('speaking_exercises', function (Blueprint $table) {
            $table->foreignUuid('reference_audio_media_id')
                ->nullable()
                ->after('target_translation')
                ->constrained('media_files')
                ->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('speaking_exercises', function (Blueprint $table) {
            $table->dropForeign(['reference_audio_media_id']);
            $table->dropColumn('reference_audio_media_id');
        });
    }
};
