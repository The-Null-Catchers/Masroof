<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /** Fixed categories (rent, bills, subscriptions…) drive the fixed-vs-variable analysis. */
    public function up(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            $table->boolean('is_fixed')->default(false)->after('type');
        });

        DB::table('categories')
            ->whereIn('default_key', ['rent', 'bills', 'internet', 'mobile', 'subscriptions'])
            ->update(['is_fixed' => true]);
    }

    public function down(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            $table->dropColumn('is_fixed');
        });
    }
};
