<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('speaking_attempts', function (Blueprint $table): void {
            $table->string('capture_source', 32)->default('web_microphone')->after('audio_duration_seconds');
        });
    }

    public function down(): void
    {
        Schema::table('speaking_attempts', function (Blueprint $table): void {
            $table->dropColumn('capture_source');
        });
    }
};
