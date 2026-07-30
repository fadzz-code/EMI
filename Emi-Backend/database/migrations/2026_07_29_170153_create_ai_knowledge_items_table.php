<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_knowledge_items', function (Blueprint $table) {
            $table->id(); // Tetap menggunakan Auto-increment BigInt untuk tabel ini
            $table->string('title');
            $table->string('source_type'); 
            $table->string('source_path'); 
            $table->string('status')->default('pending'); 
            
            // PERBAIKAN DI SINI: Gunakan foreignUuid karena tabel users menggunakan UUID
            $table->foreignUuid('created_by')->constrained('users')->cascadeOnDelete();
            
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_knowledge_items');
    }
};