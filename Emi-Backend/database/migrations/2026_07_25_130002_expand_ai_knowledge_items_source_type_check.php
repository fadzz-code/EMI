<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::getConnection()->getDriverName() !== 'pgsql') {
            return;
        }

        DB::statement('ALTER TABLE ai_knowledge_items DROP CONSTRAINT IF EXISTS ai_knowledge_items_source_type_check');
        DB::statement("ALTER TABLE ai_knowledge_items ADD CONSTRAINT ai_knowledge_items_source_type_check CHECK (source_type IN ('manual', 'link', 'pdf', 'docx', 'txt'))");
    }

    public function down(): void
    {
        if (Schema::getConnection()->getDriverName() !== 'pgsql') {
            return;
        }

        DB::statement('ALTER TABLE ai_knowledge_items DROP CONSTRAINT IF EXISTS ai_knowledge_items_source_type_check');
        DB::statement("ALTER TABLE ai_knowledge_items ADD CONSTRAINT ai_knowledge_items_source_type_check CHECK (source_type IN ('manual', 'link', 'pdf'))");
    }
};
