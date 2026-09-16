<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('budgets', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('user_id')->constrained()->cascadeOnDelete();
            $table->string('name', 60);
            // monthly | weekly | custom. Monthly follows the user's financial month start.
            $table->string('period', 10);
            $table->char('currency', 3);
            $table->bigInteger('amount');
            // Only for custom periods (inclusive dates in the user's timezone).
            $table->date('starts_on')->nullable();
            $table->date('ends_on')->nullable();
            // Percentages that trigger alerts, e.g. [50, 75, 90, 100].
            $table->json('alert_thresholds');
            $table->timestamp('archived_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['user_id', 'archived_at']);
        });

        // Empty scope means the budget covers all expense categories.
        Schema::create('budget_categories', function (Blueprint $table) {
            $table->foreignUlid('budget_id')->constrained()->cascadeOnDelete();
            $table->foreignUlid('category_id')->constrained()->cascadeOnDelete();
            $table->primary(['budget_id', 'category_id']);
        });

        if (DB::getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE budgets ADD CONSTRAINT budgets_period_check CHECK (period IN ('monthly','weekly','custom'))");
            DB::statement('ALTER TABLE budgets ADD CONSTRAINT budgets_amount_positive CHECK (amount > 0)');
            DB::statement("ALTER TABLE budgets ADD CONSTRAINT budgets_custom_dates CHECK (
                (period = 'custom' AND starts_on IS NOT NULL AND ends_on IS NOT NULL AND ends_on >= starts_on)
                OR (period <> 'custom')
            )");
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('budget_categories');
        Schema::dropIfExists('budgets');
    }
};
