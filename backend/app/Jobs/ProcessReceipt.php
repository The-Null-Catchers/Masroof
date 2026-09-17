<?php

namespace App\Jobs;

use App\Models\Receipt;
use App\Services\Ocr\CategorySuggester;
use App\Services\Ocr\OcrException;
use App\Services\Ocr\OcrProvider;
use App\Services\Ocr\ReceiptParser;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;

class ProcessReceipt implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;

    public int $timeout = 120;

    public function __construct(public readonly string $receiptId) {}

    public function handle(OcrProvider $ocr, ReceiptParser $parser, CategorySuggester $suggester): void
    {
        $receipt = Receipt::query()->with('user')->find($this->receiptId);
        if ($receipt === null || $receipt->status === 'processed') {
            return;
        }
        $receipt->update(['status' => 'processing', 'ocr_provider' => $ocr->name()]);

        try {
            $text = $ocr->recognize(Storage::disk('local')->path($receipt->file_path), $receipt->mime_type);
        } catch (OcrException $e) {
            Log::warning('Receipt OCR failed', ['receipt_id' => $receipt->id, 'error' => $e->getMessage()]);
            $receipt->update(['status' => 'failed', 'error' => 'ocr_failed']);

            return;
        }

        $fields = $parser->parse($text, $receipt->user->currency);
        $fields['suggested_category_id'] = $suggester->suggest($receipt->user, $fields['merchant']);

        $receipt->update([
            'status' => 'processed',
            'raw_text' => mb_substr($text, 0, 20_000),
            'extracted' => $fields,
            'processed_at' => now(),
        ]);
    }
}
