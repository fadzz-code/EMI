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
        Schema::create('teacher_class_assignments', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('teacher_id')->index();
            $table->uuid('class_id')->index();
            $table->uuid('assigned_by');
            $table->boolean('is_active')->default(true)->index();
            $table->timestamp('assigned_at');
            $table->timestamp('ended_at')->nullable();
            $table->timestamps();

            $table->foreign('teacher_id')->references('id')->on('users')->restrictOnDelete();
            $table->foreign('class_id')->references('id')->on('classes')->restrictOnDelete();
            $table->foreign('assigned_by')->references('id')->on('users')->restrictOnDelete();
        });

        DB::statement('CREATE UNIQUE INDEX unique_active_teacher_assignment ON teacher_class_assignments (teacher_id) WHERE is_active = true');
        DB::statement('CREATE UNIQUE INDEX unique_active_teacher_per_class ON teacher_class_assignments (class_id) WHERE is_active = true');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('teacher_class_assignments');
    }
};
