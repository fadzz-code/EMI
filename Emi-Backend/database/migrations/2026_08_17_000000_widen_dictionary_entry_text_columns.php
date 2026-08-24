<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('dictionary_entries', function (Blueprint $table) {
            $table->text('indonesia')->change();
            $table->text('english')->change();
            $table->text('mekongga')->change();
            $table->text('indonesia_normalized')->change();
            $table->text('english_normalized')->change();
            $table->text('mekongga_normalized')->change();
        });
    }

    public function down(): void
    {
        Schema::table('dictionary_entries', function (Blueprint $table) {
            $table->string('indonesia')->change();
            $table->string('english')->change();
            $table->string('mekongga')->change();
            $table->string('indonesia_normalized')->change();
            $table->string('english_normalized')->change();
            $table->string('mekongga_normalized')->change();
        });
    }
};
