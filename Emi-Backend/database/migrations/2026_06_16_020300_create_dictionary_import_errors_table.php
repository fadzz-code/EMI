<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('dictionary_import_errors', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('import_job_id')->constrained('dictionary_import_jobs')->cascadeOnDelete();
            $table->unsignedInteger('row_number')->nullable();
            $table->string('field')->nullable();
            $table->string('code');
            $table->text('message');
            $table->jsonb('raw_data')->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index('import_job_id');
            $table->index('row_number');
            $table->index('code');
            $table->index('created_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('dictionary_import_errors');
    }
};
