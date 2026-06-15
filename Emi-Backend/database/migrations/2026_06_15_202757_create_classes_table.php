<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('classes', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('school_id')->index();
            $table->string('name');
            $table->string('grade_level')->nullable();
            $table->string('academic_year')->index();
            $table->string('status')->default('active')->index();
            $table->uuid('created_by');
            $table->timestamps();

            $table->unique(['school_id', 'name', 'academic_year'], 'classes_school_name_academic_year_unique');
            $table->foreign('school_id')->references('id')->on('schools')->restrictOnDelete();
            $table->foreign('created_by')->references('id')->on('users')->restrictOnDelete();
        });

        DB::statement("ALTER TABLE classes ADD CONSTRAINT classes_status_check CHECK (status IN ('active', 'inactive'))");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('classes');
    }
};
