<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Wajib: Aktifkan ekstensi pgvector di PostgreSQL
        // DB::statement('CREATE EXTENSION IF NOT EXISTS vector;');

        Schema::create('ai_knowledge_chunks', function (Blueprint $table) {
            $table->id();
            // Relasi ke dokumen referensi
            $table->foreignId('ai_knowledge_item_id')
                  ->constrained('ai_knowledge_items')
                  ->cascadeOnDelete();
            
            // Potongan teks (500-800 karakter)
            $table->text('chunk_text');
            $table->timestamps();
        });

        // 2. Tambahkan kolom embedding dengan tipe vector 3072 dimensi
        DB::statement('ALTER TABLE ai_knowledge_chunks ADD COLUMN embedding vector(3072);');

        // 3. (KITA MATIKAN SEMENTARA)
        // Karena gemini-embedding-2 menggunakan 3072 dimensi, ia melebihi batas 2000 dimensi HNSW pgvector.
        // Tanpa HNSW, pgvector akan menggunakan pencarian Sequential/Exact yang justru 100% lebih akurat!
        // DB::statement('CREATE INDEX ai_knowledge_chunks_embedding_hnsw_idx ON ai_knowledge_chunks USING hnsw (embedding vector_cosine_ops);');
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_knowledge_chunks');
    }
};