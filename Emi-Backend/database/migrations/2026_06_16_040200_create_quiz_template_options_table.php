<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('quiz_template_options', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('quiz_template_question_id')->constrained('quiz_template_questions')->cascadeOnDelete();
            $table->text('option_text');
            $table->boolean('is_correct')->default(false);
            $table->unsignedInteger('order_number');
            $table->timestamps();
            $table->softDeletes();

            $table->index('quiz_template_question_id');
            $table->index('order_number');
            $table->index('deleted_at');
        });

        DB::statement('ALTER TABLE quiz_template_options ADD CONSTRAINT quiz_template_options_order_check CHECK (order_number > 0)');
        DB::statement('CREATE UNIQUE INDEX unique_active_quiz_template_option_order ON quiz_template_options (quiz_template_question_id, order_number) WHERE deleted_at IS NULL');
    }

    public function down(): void
    {
        Schema::dropIfExists('quiz_template_options');
    }
};
