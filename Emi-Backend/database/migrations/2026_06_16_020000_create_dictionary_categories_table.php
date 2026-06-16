<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('dictionary_categories', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('name');
            $table->string('slug')->unique();
            $table->text('description')->nullable();
            $table->string('status')->default('active');
            $table->foreignUuid('created_by')->constrained('users')->restrictOnDelete();
            $table->foreignUuid('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->softDeletes();

            $table->index('name');
            $table->index('slug');
            $table->index('status');
        });

        DB::statement("ALTER TABLE dictionary_categories ADD CONSTRAINT dictionary_categories_status_check CHECK (status IN ('active', 'inactive'))");
        DB::statement('CREATE UNIQUE INDEX unique_active_dictionary_category_name_ci ON dictionary_categories (LOWER(name)) WHERE deleted_at IS NULL');
    }

    public function down(): void
    {
        Schema::dropIfExists('dictionary_categories');
    }
};
