<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('accounts', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('user_id')->constrained()->cascadeOnDelete();
            $table->string('name', 60);
            $table->string('type', 20);
            $table->char('currency', 3);
            // All money is stored as integer minor units (e.g. halalas, cents).
            $table->bigInteger('opening_balance')->default(0);
            $table->bigInteger('balance')->default(0);
            $table->string('color', 7)->nullable();
            $table->string('icon', 40)->nullable();
            $table->text('notes')->nullable();
            $table->boolean('include_in_total')->default(true);
            $table->timestamp('archived_at')->nullable();
            $table->unsignedInteger('sort_order')->default(0);
            $table->timestamps();
            $table->softDeletes();

            $table->index(['user_id', 'archived_at']);
        });

        if (DB::getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE accounts ADD CONSTRAINT accounts_type_check CHECK (type IN ('cash','bank','credit_card','savings','e_wallet','other'))");
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('accounts');
    }
};
