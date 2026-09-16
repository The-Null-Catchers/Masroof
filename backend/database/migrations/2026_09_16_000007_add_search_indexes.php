<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

return new class extends Migration
{
    /** A failed CREATE EXTENSION must not abort a surrounding transaction. */
    public $withinTransaction = false;

    /**
     * Trigram indexes make ILIKE '%term%' searches on merchant and notes fast.
     * pg_trgm needs CREATE privilege; without it search still works unindexed.
     */
    public function up(): void
    {
        if (DB::getDriverName() !== 'pgsql') {
            return;
        }

        try {
            DB::statement('CREATE EXTENSION IF NOT EXISTS pg_trgm');
        } catch (Throwable $e) {
            Log::warning('pg_trgm unavailable; transaction search will not use trigram indexes.', ['error' => $e->getMessage()]);

            return;
        }

        DB::statement('CREATE INDEX IF NOT EXISTS transactions_merchant_trgm ON transactions USING gin (merchant gin_trgm_ops)');
        DB::statement('CREATE INDEX IF NOT EXISTS transactions_note_trgm ON transactions USING gin (note gin_trgm_ops)');
    }

    public function down(): void
    {
        DB::statement('DROP INDEX IF EXISTS transactions_merchant_trgm');
        DB::statement('DROP INDEX IF EXISTS transactions_note_trgm');
    }
};
