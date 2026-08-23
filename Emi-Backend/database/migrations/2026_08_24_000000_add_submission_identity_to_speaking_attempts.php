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
            $table->timestamp('submitted_at')->nullable()->after('reviewed_at');
        });

        DB::statement(<<<'SQL'
            WITH ranked AS (
                SELECT id, row_number() OVER (
                    PARTITION BY student_id, speaking_exercise_id
                    ORDER BY
                        CASE WHEN review_status = 'reviewed' THEN 0 ELSE 1 END,
                        CASE WHEN review_status = 'reviewed' THEN reviewed_at END DESC NULLS LAST,
                        created_at DESC,
                        id DESC
                ) AS rank
                FROM speaking_attempts
                WHERE deleted_at IS NULL
                  AND (review_status = 'reviewed' OR analysis_status = 'completed')
            )
            UPDATE speaking_attempts AS attempts
            SET submitted_at = attempts.created_at
            FROM ranked
            WHERE attempts.id = ranked.id
              AND ranked.rank = 1
            SQL);

        DB::statement('CREATE UNIQUE INDEX speaking_attempts_active_student_exercise_unique ON speaking_attempts (student_id, speaking_exercise_id) WHERE deleted_at IS NULL AND submitted_at IS NOT NULL');
    }

    public function down(): void
    {
        DB::statement('DROP INDEX IF EXISTS speaking_attempts_active_student_exercise_unique');

        Schema::table('speaking_attempts', function (Blueprint $table) {
            $table->dropColumn('submitted_at');
        });
    }
};
