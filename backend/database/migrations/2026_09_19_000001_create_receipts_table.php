<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('receipts', function (Blueprint $table) {
            $table->ulid('id')->primary();
            $table->foreignUlid('user_id')->constrained()->cascadeOnDelete();
            $table->foreignUlid('transaction_id')->nullable()->constrained()->nullOnDelete();
            $table->string('file_path');
            $table->string('mime_type', 60);
            $table->unsignedInteger('size');
            // uploaded | processing | processed | failed
            $table->string('status', 12)->default('uploaded');
            $table->string('ocr_provider', 30)->nullable();
            $table->text('raw_text')->nullable();
            // merchant, total (minor), currency, date, suggested_category_id, confidence
            $table->json('extracted')->nullable();
            $table->string('error', 255)->nullable();
            $table->timestamp('processed_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('receipts');
    }
};
