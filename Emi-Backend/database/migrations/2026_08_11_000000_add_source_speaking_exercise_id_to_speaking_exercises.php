<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('speaking_exercises', function (Blueprint $table) {
            $table->foreignUuid('source_speaking_exercise_id')
                ->nullable()
                ->after('classroom_id')
                ->constrained('speaking_exercises')
                ->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('speaking_exercises', function (Blueprint $table) {
            $table->dropConstrainedForeignId('source_speaking_exercise_id');
        });
    }
};
