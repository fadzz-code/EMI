<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::transaction(function () {
            $this->safeMergeDuplicateEntries();
        });
    }

    public function down(): void
    {
        // Data cleanup migration: not reversible without a backup.
    }

    private function safeMergeDuplicateEntries(): void
    {
        $normalizedGroups = DB::table('dictionary_entries as d')
            ->whereNull('d.deleted_at')
            ->where('d.status', 'active')
            ->select('d.indonesia_normalized')
            ->groupBy('d.indonesia_normalized')
            ->havingRaw('COUNT(*) > 1')
            ->orderBy('d.indonesia_normalized')
            ->pluck('d.indonesia_normalized');

        foreach ($normalizedGroups as $normalized) {
            $rows = DB::table('dictionary_entries as d')
                ->leftJoin('dictionary_categories as c', 'c.id', '=', 'd.category_id')
                ->whereNull('d.deleted_at')
                ->where('d.status', 'active')
                ->where('d.indonesia_normalized', $normalized)
                ->select('d.*', 'c.name as category_name')
                ->orderBy('d.created_at')
                ->orderBy('d.id')
                ->get();

            if (count($rows) < 2) {
                continue;
            }

            if (! $this->isSafeGroup($rows)) {
                continue;
            }

            $canonical = $rows->first();

            foreach ($rows as $row) {
                if ($row->id === $canonical->id) {
                    continue;
                }

                DB::table('dictionary_sentence_examples')
                    ->where('dictionary_entry_id', $row->id)
                    ->whereNull('deleted_at')
                    ->update(['dictionary_entry_id' => $canonical->id]);

                $this->mergeEntryFields($canonical, $row);

                DB::table('dictionary_entries')
                    ->where('id', $row->id)
                    ->update(['deleted_at' => now()]);
            }

            $this->dedupeSentences($canonical->id);
        }
    }

    private function isSafeGroup($rows): bool
    {
        $mekongga = [];
        $english = [];
        $category = [];

        foreach ($rows as $row) {
            if (! empty($row->mekongga_normalized)) {
                $mekongga[$row->mekongga_normalized] = true;
            }
            if (! empty($row->english_normalized)) {
                $english[$row->english_normalized] = true;
            }
            if (! empty($row->category_name)) {
                $category[$this->normalize($row->category_name)] = true;
            }
        }

        return count($mekongga) <= 1 && count($english) <= 1 && count($category) <= 1;
    }

    private function mergeEntryFields($canonical, $row): void
    {
        $updates = [];

        if (empty($canonical->mekongga) && ! empty($row->mekongga)) {
            $updates['mekongga'] = $row->mekongga;
            $updates['mekongga_normalized'] = $row->mekongga_normalized;
        }

        if (empty($canonical->english) && ! empty($row->english)) {
            $updates['english'] = $row->english;
            $updates['english_normalized'] = $row->english_normalized;
        }

        if (empty($canonical->category_id) && ! empty($row->category_id)) {
            $updates['category_id'] = $row->category_id;
        }

        if (empty($canonical->indonesia) && ! empty($row->indonesia)) {
            $updates['indonesia'] = $row->indonesia;
        }

        if (empty($canonical->audio_media_id) && ! empty($row->audio_media_id)
            && ! $this->tripleExists($canonical, $updates, $row)) {
            $updates['audio_media_id'] = $row->audio_media_id;
        }

        if (count($updates) > 0) {
            DB::table('dictionary_entries')
                ->where('id', $canonical->id)
                ->update($updates);
        }
    }

    private function tripleExists($canonical, array $mergeUpdates, $row): bool
    {
        $indonesia = $canonical->indonesia_normalized;
        $english = $canonical->english_normalized ?? $mergeUpdates['english_normalized'] ?? null;
        $mekongga = $canonical->mekongga_normalized ?? $mergeUpdates['mekongga_normalized'] ?? null;

        return DB::table('dictionary_entries')
            ->whereNull('deleted_at')
            ->where('status', 'active')
            ->where('id', '!=', $canonical->id)
            ->where('id', '!=', $row->id)
            ->where('indonesia_normalized', $indonesia)
            ->where('english_normalized', $english)
            ->where('mekongga_normalized', $mekongga)
            ->exists();
    }

    private function dedupeSentences(string $entryId): void
    {
        DB::statement(<<<'SQL'
            UPDATE dictionary_sentence_examples AS duplicate
            SET deleted_at = NOW()
            WHERE duplicate.deleted_at IS NULL
              AND duplicate.dictionary_entry_id = ?
              AND duplicate.id NOT IN (
                  SELECT keep.id
                  FROM (
                      SELECT id,
                             ROW_NUMBER() OVER (
                                 PARTITION BY example_indonesia_normalized
                                 ORDER BY created_at ASC, id ASC
                             ) AS row_num
                      FROM dictionary_sentence_examples
                      WHERE deleted_at IS NULL
                        AND dictionary_entry_id = ?
                  ) AS keep
                  WHERE keep.row_num = 1
              )
        SQL, [$entryId, $entryId]);
    }

    private function normalize(string $value): string
    {
        return mb_strtolower(trim(preg_replace('/\s+/', ' ', $value)));
    }
};
