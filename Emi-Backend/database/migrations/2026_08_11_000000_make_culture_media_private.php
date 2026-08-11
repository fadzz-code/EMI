<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::table('media_files')
            ->where('purpose', 'culture_media')
            ->where('visibility', 'public')
            ->update(['visibility' => 'private']);
    }

    public function down(): void
    {
        DB::table('media_files')
            ->where('purpose', 'culture_media')
            ->where('visibility', 'private')
            ->update(['visibility' => 'public']);
    }
};
