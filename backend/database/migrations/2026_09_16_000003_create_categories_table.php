<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('categories', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('user_id')->constrained()->cascadeOnDelete();
            $table->ulid('parent_id')->nullable()->index();
            $table->string('name', 60);
            // Set for built-in categories that have not been renamed, so clients can localize them.
            $table->string('default_key', 40)->nullable();
            $table->string('type', 10);
            $table->string('color', 7)->nullable();
            $table->string('icon', 40)->nullable();
            $table->timestamp('archived_at')->nullable();
            $table->unsignedInteger('sort_order')->default(0);
            $table->timestamps();
            $table->softDeletes();

            $table->index(['user_id', 'type']);
        });

        // Self-reference is added after the primary key exists.
        Schema::table('categories', function (Blueprint $table) {
            $table->foreign('parent_id')->references('id')->on('categories')->nullOnDelete();
        });

        if (DB::getDriverName() === 'pgsql') {
            DB::statement("ALTER TABLE categories ADD CONSTRAINT categories_type_check CHECK (type IN ('income','expense'))");
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('categories');
    }
};
