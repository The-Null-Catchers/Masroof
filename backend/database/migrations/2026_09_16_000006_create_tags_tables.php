<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('tags', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('user_id')->constrained()->cascadeOnDelete();
            $table->string('name', 40);
            $table->string('color', 7)->nullable();
            $table->timestamps();
        });

        Schema::create('transaction_tags', function (Blueprint $table) {
            $table->foreignUlid('transaction_id')->constrained()->cascadeOnDelete();
            $table->foreignUlid('tag_id')->constrained()->cascadeOnDelete();
            $table->primary(['transaction_id', 'tag_id']);
            $table->index('tag_id');
        });

        if (DB::getDriverName() === 'pgsql') {
            // Tag names are unique per user regardless of letter case.
            DB::statement('CREATE UNIQUE INDEX tags_user_name_unique ON tags (user_id, lower(name))');
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('transaction_tags');
        Schema::dropIfExists('tags');
    }
};
