<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        $this->resolveDuplicateActiveSentences();

        DB::statement('DROP INDEX IF EXISTS unique_active_dictionary_sentence_example_pair');

        Schema::table('dictionary_sentence_examples', function (Blueprint $table) {
            $table->text('example_mekongga_normalized')->change();
            $table->text('example_indonesia_normalized')->change();
            $table->foreignUuid('audio_media_id')->nullable()->after('code')->constrained('media_files')->nullOnDelete();
        });

        DB::statement('CREATE UNIQUE INDEX unique_active_dictionary_sentence_per_entry ON dictionary_sentence_examples (dictionary_entry_id, example_indonesia_normalized) WHERE deleted_at IS NULL');
    }

    public function down(): void
    {
        DB::statement('DROP INDEX IF EXISTS unique_active_dictionary_sentence_per_entry');

        Schema::table('dictionary_sentence_examples', function (Blueprint $table) {
            $table->dropForeign(['audio_media_id']);
            $table->dropColumn('audio_media_id');
            $table->string('example_mekongga_normalized')->change();
            $table->string('example_indonesia_normalized')->change();
        });

        DB::statement('CREATE UNIQUE INDEX unique_active_dictionary_sentence_example_pair ON dictionary_sentence_examples (example_mekongga_normalized, example_indonesia_normalized) WHERE deleted_at IS NULL');
    }

    private function resolveDuplicateActiveSentences(): void
    {
        DB::statement(<<<'SQL'
            UPDATE dictionary_sentence_examples AS duplicate
            SET deleted_at = NOW()
            WHERE duplicate.deleted_at IS NULL
              AND duplicate.id NOT IN (
                  SELECT keep.id
                  FROM (
                      SELECT id,
                             ROW_NUMBER() OVER (
                                 PARTITION BY dictionary_entry_id, example_indonesia_normalized
                                 ORDER BY created_at ASC, id ASC
                             ) AS row_num
                      FROM dictionary_sentence_examples
                      WHERE deleted_at IS NULL
                  ) AS keep
                  WHERE keep.row_num = 1
              )
        SQL);
    }
};
