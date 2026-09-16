<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('goals', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('user_id')->constrained()->cascadeOnDelete();
            $table->string('name', 60);
            // emergency_fund | laptop | car | travel | wedding | home | custom
            $table->string('kind', 20)->default('custom');
            $table->char('currency', 3);
            $table->bigInteger('target_amount');
            // Maintained from goal_transactions by GoalService.
            $table->bigInteger('current_amount')->default(0);
            $table->date('target_date')->nullable();
            $table->foreignUlid('account_id')->nullable()->constrained()->nullOnDelete();
            $table->string('icon', 40)->nullable();
            $table->string('color', 7)->nullable();
            $table->text('notes')->nullable();
            $table->timestamp('achieved_at')->nullable();
            $table->timestamp('archived_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['user_id', 'archived_at']);
        });

        Schema::create('goal_transactions', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('goal_id')->constrained()->cascadeOnDelete();
            // contribution | withdrawal
            $table->string('type', 12);
            $table->bigInteger('amount');
            $table->timestamp('occurred_at');
            $table->string('note', 255)->nullable();
            $table->timestamps();

            $table->index(['goal_id', 'occurred_at']);
        });

        if (DB::getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE goals ADD CONSTRAINT goals_target_positive CHECK (target_amount > 0)');
            DB::statement('ALTER TABLE goals ADD CONSTRAINT goals_current_non_negative CHECK (current_amount >= 0)');
            DB::statement("ALTER TABLE goal_transactions ADD CONSTRAINT goal_transactions_type_check CHECK (type IN ('contribution','withdrawal'))");
            DB::statement('ALTER TABLE goal_transactions ADD CONSTRAINT goal_transactions_amount_positive CHECK (amount > 0)');
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('goal_transactions');
        Schema::dropIfExists('goals');
    }
};
