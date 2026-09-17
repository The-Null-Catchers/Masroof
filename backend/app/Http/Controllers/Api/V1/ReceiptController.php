<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\TransactionRequest;
use App\Http\Resources\V1\TransactionResource;
use App\Jobs\ProcessReceipt;
use App\Models\Receipt;
use App\Services\TransactionService;
use App\Support\Money;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\StreamedResponse;

/**
 * Receipt workflow: upload → OCR (queued) → user reviews the extracted
 * fields → confirm creates the transaction and links the receipt.
 */
class ReceiptController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            // Photos from phones; HEIC is converted client-side.
            'file' => ['required', 'file', 'mimes:jpg,jpeg,png,webp', 'max:10240'],
        ]);
        $file = $request->file('file');
        $userId = $request->user()->id;
        $path = $file->storeAs("receipts/{$userId}", Str::ulid().'.'.$file->extension(), 'local');

        $receipt = new Receipt([
            'file_path' => $path,
            'mime_type' => (string) $file->getMimeType(),
            'size' => (int) $file->getSize(),
        ]);
        $receipt->user_id = $userId;
        $receipt->save();

        ProcessReceipt::dispatch($receipt->id);

        return response()->json(['data' => $this->present($receipt->refresh())], 202);
    }

    public function show(Request $request, Receipt $receipt): JsonResponse
    {
        $this->authorizeOwner($request, $receipt);

        return response()->json(['data' => $this->present($receipt)]);
    }

    public function image(Request $request, Receipt $receipt): StreamedResponse
    {
        $this->authorizeOwner($request, $receipt);

        return Storage::disk('local')->response($receipt->file_path, null, ['Content-Type' => $receipt->mime_type, 'Cache-Control' => 'private, max-age=3600']);
    }

    /**
     * Creates the transaction from the (possibly edited) fields. Uses the same
     * validation and balance logic as any other transaction.
     */
    public function confirm(TransactionRequest $request, Receipt $receipt, TransactionService $service): JsonResponse
    {
        $this->authorizeOwner($request, $receipt);
        abort_if($receipt->transaction_id !== null, 409, __('masroof.receipt_already_used'));

        $transaction = DB::transaction(function () use ($request, $receipt, $service) {
            $transaction = $service->create($request->user(), $request->toAttributes());
            $receipt->update(['transaction_id' => $transaction->id]);

            return $transaction;
        });

        return (new TransactionResource($transaction->load(['account', 'transferAccount', 'category', 'tags', 'receipt:id,transaction_id'])))->response()->setStatusCode(201);
    }

    public function destroy(Request $request, Receipt $receipt): JsonResponse
    {
        $this->authorizeOwner($request, $receipt);
        Storage::disk('local')->delete($receipt->file_path);
        $receipt->delete();

        return response()->json(null, 204);
    }

    /** @return array<string, mixed> */
    private function present(Receipt $receipt): array
    {
        $extracted = $receipt->extracted;

        return [
            'id' => $receipt->id,
            'status' => $receipt->status,
            'error' => $receipt->error === null ? null : __('masroof.receipt_ocr_failed'),
            'transaction_id' => $receipt->transaction_id,
            'provider' => $receipt->ocr_provider,
            'extracted' => $extracted === null ? null : [
                'merchant' => $extracted['merchant'] ?? null,
                'total' => $extracted['total_decimal'] ?? null,
                'total_minor' => $extracted['total'] ?? null,
                'currency' => $extracted['currency'] ?? null,
                'date' => $extracted['date'] ?? null,
                'suggested_category_id' => $extracted['suggested_category_id'] ?? null,
                'confidence' => $extracted['confidence'] ?? 0,
                'display_total' => isset($extracted['total'], $extracted['currency']) ? Money::display((int) $extracted['total'], (string) $extracted['currency']) : null,
            ],
            'image_url' => rtrim((string) config('app.url'), '/')."/api/v1/receipts/{$receipt->id}/image",
            'created_at' => $receipt->created_at?->toIso8601String(),
        ];
    }

    private function authorizeOwner(Request $request, Receipt $receipt): void
    {
        abort_unless($receipt->user_id === $request->user()->id, 404);
    }
}
