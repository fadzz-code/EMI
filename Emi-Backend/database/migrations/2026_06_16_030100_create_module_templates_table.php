<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('module_templates', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('status')->default('draft');
            $table->foreignUuid('created_by')->constrained('users')->restrictOnDelete();
            $table->foreignUuid('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('published_at')->nullable();
            $table->timestamp('archived_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index('title');
            $table->index('status');
            $table->index('created_by');
            $table->index('deleted_at');
        });

        DB::statement("ALTER TABLE module_templates ADD CONSTRAINT module_templates_status_check CHECK (status IN ('draft', 'published', 'archived'))");
    }

    public function down(): void
    {
        Schema::dropIfExists('module_templates');
    }
};
