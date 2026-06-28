<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('class_culture_items', function (Blueprint $table) {
            $table->uuid('admin_group_id')->nullable()->after('source_culture_template_item_id');
            $table->string('created_scope')->default('teacher')->after('admin_group_id');
            $table->index('admin_group_id');
            $table->index(['created_scope', 'status']);
        });
    }

    public function down(): void
    {
        Schema::table('class_culture_items', function (Blueprint $table) {
            $table->dropIndex(['admin_group_id']);
            $table->dropIndex(['created_scope', 'status']);
            $table->dropColumn(['admin_group_id', 'created_scope']);
        });
    }
};
