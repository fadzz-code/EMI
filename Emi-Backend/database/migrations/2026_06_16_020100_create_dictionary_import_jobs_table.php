<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('dictionary_import_jobs', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('uploaded_by')->constrained('users')->restrictOnDelete();
            $table->string('status')->default('previewing');
            $table->string('duplicate_strategy')->default('skip');
            $table->string('csv_disk');
            $table->string('csv_path');
            $table->string('csv_original_name');
            $table->unsignedBigInteger('csv_size_bytes');
            $table->string('csv_checksum_sha256', 64);
            $table->string('audio_zip_disk')->nullable();
            $table->string('audio_zip_path')->nullable();
            $table->string('audio_zip_original_name')->nullable();
            $table->unsignedBigInteger('audio_zip_size_bytes')->nullable();
            $table->string('audio_zip_checksum_sha256', 64)->nullable();
            $table->unsignedInteger('total_rows')->default(0);
            $table->unsignedInteger('valid_rows')->default(0);
            $table->unsignedInteger('invalid_rows')->default(0);
            $table->unsignedInteger('inserted_rows')->default(0);
            $table->unsignedInteger('updated_rows')->default(0);
            $table->unsignedInteger('skipped_rows')->default(0);
            $table->unsignedInteger('warning_count')->default(0);
            $table->jsonb('summary')->nullable();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('failed_at')->nullable();
            $table->string('failure_code')->nullable();
            $table->text('failure_message')->nullable();
            $table->timestamps();

            $table->index('uploaded_by');
            $table->index('status');
            $table->index('duplicate_strategy');
            $table->index('created_at');
        });

        DB::statement("ALTER TABLE dictionary_import_jobs ADD CONSTRAINT dictionary_import_jobs_status_check CHECK (status IN ('previewing', 'preview_ready', 'queued', 'processing', 'completed', 'completed_with_errors', 'failed'))");
        DB::statement("ALTER TABLE dictionary_import_jobs ADD CONSTRAINT dictionary_import_jobs_duplicate_strategy_check CHECK (duplicate_strategy IN ('skip', 'update', 'reject'))");
    }

    public function down(): void
    {
        Schema::dropIfExists('dictionary_import_jobs');
    }
};
