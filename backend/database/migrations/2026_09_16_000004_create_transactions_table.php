<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('transactions', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('user_id')->constrained()->cascadeOnDelete();
            $table->foreignUlid('account_id')->constrained()->cascadeOnDelete();
            $table->foreignUlid('category_id')->nullable()->constrained()->nullOnDelete();
            $table->string('type', 10);
            // Positive integer minor units in the account's currency.
            $table->bigInteger('amount');
            $table->char('currency', 3);
            // Transfers only: destination account and the amount credited to it
            // (differs from `amount` when the accounts use different currencies).
            $table->foreignUlid('transfer_account_id')->nullable()->constrained('accounts')->cascadeOnDelete();
            $table->bigInteger('transfer_amount')->nullable();
            $table->timestamp('occurred_at');
            $table->string('payee', 120)->nullable();
            $table->text('note')->nullable();
            $table->timestamps();
            $table->softDeletes();

            $table->index(['user_id', 'occurred_at']);
            $table->index(['account_id', 'occurred_at']);
            $table->index(['transfer_account_id']);
            $table->index(['category_id', 'occurred_at']);
        });

        if (DB::getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE transactions ADD CONSTRAINT transactions_type_check CHECK (type IN ('income','expense','transfer'))");
            DB::statement('ALTER TABLE transactions ADD CONSTRAINT transactions_amount_positive CHECK (amount > 0)');
            DB::statement("ALTER TABLE transactions ADD CONSTRAINT transactions_transfer_shape CHECK (
                (type = 'transfer' AND transfer_account_id IS NOT NULL AND transfer_amount > 0 AND transfer_account_id <> account_id AND category_id IS NULL)
                OR (type <> 'transfer' AND transfer_account_id IS NULL AND transfer_amount IS NULL)
            )");
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};
