<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('dictionary_import_jobs', function (Blueprint $table) {
            $table->string('source_format')->default('csv')->after('import_type');
        });

        DB::statement("ALTER TABLE dictionary_import_jobs ADD CONSTRAINT dictionary_import_jobs_source_format_check CHECK (source_format IN ('csv', 'xlsx'))");

        DB::statement('ALTER TABLE dictionary_import_jobs DROP CONSTRAINT IF EXISTS dictionary_import_jobs_import_type_check');
        DB::statement("ALTER TABLE dictionary_import_jobs ADD CONSTRAINT dictionary_import_jobs_import_type_check CHECK (import_type IN ('vocabulary', 'sentence_examples', 'combined'))");

        Schema::table('dictionary_import_errors', function (Blueprint $table) {
            $table->string('sheet')->nullable()->after('field');
        });
    }

    public function down(): void
    {
        Schema::table('dictionary_import_errors', function (Blueprint $table) {
            $table->dropColumn('sheet');
        });

        DB::statement('ALTER TABLE dictionary_import_jobs DROP CONSTRAINT IF EXISTS dictionary_import_jobs_import_type_check');
        DB::statement("ALTER TABLE dictionary_import_jobs ADD CONSTRAINT dictionary_import_jobs_import_type_check CHECK (import_type IN ('vocabulary', 'sentence_examples'))");

        DB::statement('ALTER TABLE dictionary_import_jobs DROP CONSTRAINT IF EXISTS dictionary_import_jobs_source_format_check');

        Schema::table('dictionary_import_jobs', function (Blueprint $table) {
            $table->dropColumn('source_format');
        });
    }
};
