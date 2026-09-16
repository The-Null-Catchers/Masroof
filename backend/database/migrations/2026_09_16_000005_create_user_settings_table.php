<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_settings', function (Blueprint $table) {
            $table->foreignUlid('user_id')->primary()->constrained()->cascadeOnDelete();
            // Minor units in the user's default currency.
            $table->bigInteger('monthly_income_estimate')->nullable();
            $table->string('main_goal', 40)->nullable();
            $table->boolean('budget_alerts')->default(true);
            $table->boolean('recurring_reminders')->default(true);
            $table->foreignUlid('default_account_id')->nullable()->constrained('accounts')->nullOnDelete();
            // Day of month on which the user's financial month starts (1-28).
            $table->unsignedTinyInteger('month_start_day')->default(1);
            $table->timestamp('onboarding_completed_at')->nullable();
            $table->timestamps();
        });

        if (DB::getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE user_settings ADD CONSTRAINT user_settings_month_start_check CHECK (month_start_day BETWEEN 1 AND 28)');
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('user_settings');
    }
};
