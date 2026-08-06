<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('dictionary_entries', function (Blueprint $table) {
            $table->dropForeign(['category_id']);
            $table->foreignUuid('category_id')->nullable()->change();
            $table->foreign('category_id')->references('id')->on('dictionary_categories')->restrictOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('dictionary_entries', function (Blueprint $table) {
            $table->dropForeign(['category_id']);
            $table->foreignUuid('category_id')->nullable(false)->change();
            $table->foreign('category_id')->references('id')->on('dictionary_categories')->restrictOnDelete();
        });
    }
};
