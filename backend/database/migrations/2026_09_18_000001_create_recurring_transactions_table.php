<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('recurring_transactions', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('user_id')->constrained()->cascadeOnDelete();
            $table->string('name', 80);
            $table->string('type', 10);
            $table->foreignUlid('account_id')->constrained()->cascadeOnDelete();
            $table->foreignUlid('category_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignUlid('transfer_account_id')->nullable()->constrained('accounts')->cascadeOnDelete();
            $table->bigInteger('amount');
            $table->bigInteger('transfer_amount')->nullable();
            $table->char('currency', 3);
            $table->string('merchant', 120)->nullable();
            $table->string('payment_method', 20)->nullable();
            $table->text('note')->nullable();
            // daily | weekly | monthly | yearly; `interval` repeats every N units (custom schedules).
            $table->string('frequency', 10);
            $table->unsignedSmallInteger('interval')->default(1);
            $table->date('starts_on');
            $table->date('ends_on')->nullable();
            // Next date (user's local calendar) that has not been generated yet.
            $table->date('next_occurrence_on')->nullable();
            // auto: create the transaction on the date; remind: only notify the user.
            $table->string('mode', 10)->default('auto');
            $table->unsignedTinyInteger('remind_days_before')->default(1);
            $table->timestamp('paused_at')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['next_occurrence_on', 'paused_at']);
            $table->index(['user_id', 'deleted_at']);
        });

        Schema::table('transactions', function (Blueprint $table) {
            $table->foreignUlid('recurring_transaction_id')->nullable()->after('user_id')->constrained()->nullOnDelete();
            $table->date('recurring_occurrence_on')->nullable()->after('recurring_transaction_id');
            // One generated transaction per rule per date: the database guarantees no duplicates.
            $table->unique(['recurring_transaction_id', 'recurring_occurrence_on']);
        });

        if (DB::getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE recurring_transactions ADD CONSTRAINT recurring_type_check CHECK (type IN ('income','expense','transfer'))");
            DB::statement("ALTER TABLE recurring_transactions ADD CONSTRAINT recurring_frequency_check CHECK (frequency IN ('daily','weekly','monthly','yearly'))");
            DB::statement("ALTER TABLE recurring_transactions ADD CONSTRAINT recurring_mode_check CHECK (mode IN ('auto','remind'))");
            DB::statement('ALTER TABLE recurring_transactions ADD CONSTRAINT recurring_amount_positive CHECK (amount > 0)');
            DB::statement('ALTER TABLE recurring_transactions ADD CONSTRAINT recurring_interval_positive CHECK (interval BETWEEN 1 AND 366)');
        }
    }

    public function down(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            $table->dropUnique(['recurring_transaction_id', 'recurring_occurrence_on']);
            $table->dropConstrainedForeignId('recurring_transaction_id');
            $table->dropColumn('recurring_occurrence_on');
        });
        Schema::dropIfExists('recurring_transactions');
    }
};
