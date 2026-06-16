<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('media_files', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('uploaded_by')->constrained('users')->restrictOnDelete();
            $table->string('purpose');
            $table->string('original_name');
            $table->string('stored_name');
            $table->string('disk');
            $table->string('path');
            $table->string('mime_type');
            $table->string('extension')->nullable();
            $table->unsignedBigInteger('size_bytes');
            $table->string('checksum_sha256', 64);
            $table->string('visibility');
            $table->jsonb('metadata')->nullable();
            $table->foreignUuid('deleted_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->softDeletes();

            $table->index('uploaded_by');
            $table->index('purpose');
            $table->index('visibility');
            $table->index('checksum_sha256');
            $table->index('created_at');
            $table->index('deleted_at');
        });

        DB::statement("ALTER TABLE media_files ADD CONSTRAINT media_files_purpose_check CHECK (purpose IN ('avatar', 'question_image', 'document', 'audio', 'speaking_recording'))");
        DB::statement("ALTER TABLE media_files ADD CONSTRAINT media_files_visibility_check CHECK (visibility IN ('public', 'private'))");
    }

    public function down(): void
    {
        Schema::dropIfExists('media_files');
    }
};
