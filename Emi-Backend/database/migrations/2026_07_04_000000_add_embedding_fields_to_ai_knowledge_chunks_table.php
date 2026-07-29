<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('ai_knowledge_chunks', function (Blueprint $table) {
            if (! Schema::hasColumn('ai_knowledge_chunks', 'embedding_provider')) {
                $table->string('embedding_provider')->nullable()->index();
            }

            if (! Schema::hasColumn('ai_knowledge_chunks', 'embedding_model')) {
                $table->string('embedding_model')->nullable();
            }

            if (! Schema::hasColumn('ai_knowledge_chunks', 'embedding_dimensions')) {
                $table->unsignedSmallInteger('embedding_dimensions')->nullable();
            }

            if (! Schema::hasColumn('ai_knowledge_chunks', 'embedded_at')) {
                $table->timestamp('embedded_at')->nullable()->index();
            }

            if (! Schema::hasColumn('ai_knowledge_chunks', 'embedding_hash')) {
                $table->string('embedding_hash')->nullable()->index();
            }

            if (! Schema::hasColumn('ai_knowledge_chunks', 'embedding_error')) {
                $table->text('embedding_error')->nullable();
            }
        });

        if ($this->canUseVectorColumn() && ! Schema::hasColumn('ai_knowledge_chunks', 'embedding')) {
            DB::statement('alter table ai_knowledge_chunks add column embedding vector(768) null');
        }
    }

    public function down(): void
    {
        Schema::table('ai_knowledge_chunks', function (Blueprint $table) {
            foreach (['embedding_provider', 'embedded_at', 'embedding_hash'] as $indexColumn) {
                if (Schema::hasColumn('ai_knowledge_chunks', $indexColumn)) {
                    $table->dropIndex('ai_knowledge_chunks_'.$indexColumn.'_index');
                }
            }
        });

        Schema::table('ai_knowledge_chunks', function (Blueprint $table) {
            foreach ([
                'embedding',
                'embedding_provider',
                'embedding_model',
                'embedding_dimensions',
                'embedded_at',
                'embedding_hash',
                'embedding_error',
            ] as $column) {
                if (Schema::hasColumn('ai_knowledge_chunks', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }

    private function canUseVectorColumn(): bool
    {
        if (DB::getDriverName() !== 'pgsql') {
            return false;
        }

        try {
            $installed = DB::selectOne("select exists (select 1 from pg_extension where extname = 'vector') as installed");

            return (bool) ($installed->installed ?? false);
        } catch (Throwable) {
            return false;
        }
    }
};
