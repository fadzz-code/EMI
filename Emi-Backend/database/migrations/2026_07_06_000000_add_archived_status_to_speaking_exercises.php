<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement('ALTER TABLE speaking_exercises DROP CONSTRAINT speaking_exercises_status_check');
        DB::statement("ALTER TABLE speaking_exercises ADD CONSTRAINT speaking_exercises_status_check CHECK (status IN ('draft', 'published', 'archived'))");
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE speaking_exercises DROP CONSTRAINT speaking_exercises_status_check');
        DB::statement("ALTER TABLE speaking_exercises ADD CONSTRAINT speaking_exercises_status_check CHECK (status IN ('draft', 'published'))");
    }
};
