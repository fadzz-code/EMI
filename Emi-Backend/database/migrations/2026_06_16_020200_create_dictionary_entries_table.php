<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('dictionary_entries', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('category_id')->constrained('dictionary_categories')->restrictOnDelete();
            $table->string('indonesia');
            $table->string('english');
            $table->string('mekongga');
            $table->string('indonesia_normalized');
            $table->string('english_normalized');
            $table->string('mekongga_normalized');
            $table->text('example_mekongga')->nullable();
            $table->text('example_indonesia')->nullable();
            $table->foreignUuid('audio_media_id')->nullable()->constrained('media_files')->nullOnDelete();
            $table->string('status')->default('active');
            $table->foreignUuid('created_by')->constrained('users')->restrictOnDelete();
            $table->foreignUuid('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignUuid('source_import_job_id')->nullable()->constrained('dictionary_import_jobs')->nullOnDelete();
            $table->timestamps();
            $table->softDeletes();

            $table->index('category_id');
            $table->index('status');
            $table->index('indonesia_normalized');
            $table->index('english_normalized');
            $table->index('mekongga_normalized');
            $table->index('audio_media_id');
            $table->index('source_import_job_id');
        });

        DB::statement("ALTER TABLE dictionary_entries ADD CONSTRAINT dictionary_entries_status_check CHECK (status IN ('active', 'inactive'))");
        DB::statement('CREATE UNIQUE INDEX unique_active_dictionary_entry_triple ON dictionary_entries (indonesia_normalized, english_normalized, mekongga_normalized) WHERE deleted_at IS NULL');
    }

    public function down(): void
    {
        Schema::dropIfExists('dictionary_entries');
    }
};
