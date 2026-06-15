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
        Schema::create('student_class_memberships', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('student_id')->index();
            $table->uuid('class_id')->index();
            $table->uuid('assigned_by');
            $table->boolean('is_active')->default(true)->index();
            $table->timestamp('joined_at');
            $table->timestamp('ended_at')->nullable();
            $table->timestamps();

            $table->foreign('student_id')->references('id')->on('users')->restrictOnDelete();
            $table->foreign('class_id')->references('id')->on('classes')->restrictOnDelete();
            $table->foreign('assigned_by')->references('id')->on('users')->restrictOnDelete();
        });

        DB::statement('CREATE UNIQUE INDEX unique_active_student_class ON student_class_memberships (student_id) WHERE is_active = true');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('student_class_memberships');
    }
};
