<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->boolean('password_must_change')->default(false)->after('password');
        });

        Schema::create('password_reset_requests', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->uuid('user_id')->index();
            $table->uuid('requested_by')->index();
            $table->string('status')->default('pending')->index();
            $table->uuid('reviewed_by')->nullable();
            $table->text('review_note')->nullable();
            $table->timestamp('reviewed_at')->nullable();
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('requested_by')->references('id')->on('users')->cascadeOnDelete();
            $table->foreign('reviewed_by')->references('id')->on('users')->nullOnDelete();
        });

        DB::statement("ALTER TABLE password_reset_requests ADD CONSTRAINT password_reset_requests_status_check CHECK (status IN ('pending', 'approved', 'rejected'))");
        DB::statement('CREATE UNIQUE INDEX unique_pending_password_reset_request ON password_reset_requests (user_id) WHERE status = \'pending\'');
    }

    public function down(): void
    {
        Schema::dropIfExists('password_reset_requests');

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('password_must_change');
        });
    }
};
