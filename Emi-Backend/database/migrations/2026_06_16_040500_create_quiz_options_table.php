<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('quiz_options', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('quiz_question_id')->constrained('quiz_questions')->cascadeOnDelete();
            $table->foreignUuid('source_quiz_template_option_id')->nullable()->constrained('quiz_template_options')->nullOnDelete();
            $table->text('option_text');
            $table->boolean('is_correct')->default(false);
            $table->unsignedInteger('order_number');
            $table->timestamps();
            $table->softDeletes();

            $table->index('quiz_question_id');
            $table->index('source_quiz_template_option_id');
            $table->index('order_number');
            $table->index('deleted_at');
        });

        DB::statement('ALTER TABLE quiz_options ADD CONSTRAINT quiz_options_order_check CHECK (order_number > 0)');
        DB::statement('CREATE UNIQUE INDEX unique_active_quiz_option_order ON quiz_options (quiz_question_id, order_number) WHERE deleted_at IS NULL');
    }

    public function down(): void
    {
        Schema::dropIfExists('quiz_options');
    }
};
