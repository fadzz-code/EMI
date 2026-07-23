<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('speaking_attempts', function (Blueprint $table) {
            $table->string('analysis_status')->default('pending')->after('status');
            $table->string('review_status')->default('pending')->after('analysis_status');
            $table->index(['student_id', 'analysis_status', 'created_at']);
            $table->index(['review_status', 'created_at']);
        });

        DB::table('speaking_attempts')->update([
            'analysis_status' => DB::raw("CASE WHEN status = 'reviewed' THEN CASE WHEN ai_error IS NOT NULL THEN 'failed' WHEN ai_score IS NOT NULL OR ai_transcription IS NOT NULL OR ai_raw_response IS NOT NULL THEN 'completed' ELSE 'pending' END ELSE status END"),
            'review_status' => DB::raw("CASE WHEN reviewed_at IS NOT NULL OR status = 'reviewed' THEN 'reviewed' ELSE 'pending' END"),
        ]);

        DB::statement("ALTER TABLE speaking_attempts ADD CONSTRAINT speaking_attempts_analysis_status_check CHECK (analysis_status IN ('pending', 'processing', 'completed', 'failed'))");
        DB::statement("ALTER TABLE speaking_attempts ADD CONSTRAINT speaking_attempts_review_status_check CHECK (review_status IN ('pending', 'reviewed'))");
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE speaking_attempts DROP CONSTRAINT IF EXISTS speaking_attempts_analysis_status_check');
        DB::statement('ALTER TABLE speaking_attempts DROP CONSTRAINT IF EXISTS speaking_attempts_review_status_check');
        Schema::table('speaking_attempts', function (Blueprint $table) {
            $table->dropIndex(['student_id', 'analysis_status', 'created_at']);
            $table->dropIndex(['review_status', 'created_at']);
            $table->dropColumn(['analysis_status', 'review_status']);
        });
    }
};
