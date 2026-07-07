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
            $table->string('import_type')->default('vocabulary')->after('duplicate_strategy');
            $table->index('import_type');
        });

        DB::statement("ALTER TABLE dictionary_import_jobs ADD CONSTRAINT dictionary_import_jobs_import_type_check CHECK (import_type IN ('vocabulary', 'sentence_examples'))");

        Schema::table('dictionary_entries', function (Blueprint $table) {
            $table->string('code')->nullable()->after('id');
            $table->string('code_normalized')->nullable()->after('code');
            $table->index('code_normalized');
        });

        Schema::create('dictionary_sentence_examples', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('dictionary_entry_id')->constrained('dictionary_entries')->cascadeOnDelete();
            $table->string('code');
            $table->text('example_mekongga');
            $table->text('example_indonesia');
            $table->string('example_mekongga_normalized');
            $table->string('example_indonesia_normalized');
            $table->string('status')->default('active');
            $table->foreignUuid('created_by')->constrained('users')->restrictOnDelete();
            $table->foreignUuid('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignUuid('source_import_job_id')->nullable()->constrained('dictionary_import_jobs')->nullOnDelete();
            $table->timestamps();
            $table->softDeletes();

            $table->index('dictionary_entry_id');
            $table->index('code');
            $table->index('status');
            $table->index('example_mekongga_normalized');
            $table->index('example_indonesia_normalized');
            $table->index('source_import_job_id');
        });

        DB::statement("ALTER TABLE dictionary_sentence_examples ADD CONSTRAINT dictionary_sentence_examples_status_check CHECK (status IN ('active', 'inactive'))");
        DB::statement('CREATE UNIQUE INDEX unique_active_dictionary_sentence_example_pair ON dictionary_sentence_examples (example_mekongga_normalized, example_indonesia_normalized) WHERE deleted_at IS NULL');
    }

    public function down(): void
    {
        Schema::dropIfExists('dictionary_sentence_examples');

        Schema::table('dictionary_entries', function (Blueprint $table) {
            $table->dropIndex(['code_normalized']);
            $table->dropColumn(['code', 'code_normalized']);
        });

        DB::statement('ALTER TABLE dictionary_import_jobs DROP CONSTRAINT IF EXISTS dictionary_import_jobs_import_type_check');

        Schema::table('dictionary_import_jobs', function (Blueprint $table) {
            $table->dropIndex(['import_type']);
            $table->dropColumn('import_type');
        });
    }
};
