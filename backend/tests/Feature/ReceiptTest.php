<?php

namespace Tests\Feature;

use App\Models\Receipt;
use App\Models\User;
use App\Services\DefaultCategories;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class ReceiptTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('local');
        $this->travelTo(Carbon::parse('2026-09-17 09:00', 'UTC'));
        $this->user = $this->signIn(User::factory()->create(['currency' => 'ILS']));
        app(DefaultCategories::class)->provision($this->user);
    }

    private function upload(): string
    {
        return $this->post('/api/v1/receipts', ['file' => UploadedFile::fake()->image('receipt.jpg', 600, 900)], ['Accept' => 'application/json'])
            ->assertAccepted()
            ->json('data.id');
    }

    public function test_upload_extracts_fields_and_suggests_category_by_keyword(): void
    {
        $id = $this->upload();
        $groceries = $this->user->categories()->where('default_key', 'groceries')->value('id');

        $this->getJson("/api/v1/receipts/{$id}")
            ->assertOk()
            ->assertJsonPath('data.status', 'processed')
            ->assertJsonPath('data.provider', 'mock')
            ->assertJsonPath('data.extracted.merchant', 'Bravo Supermarket')
            ->assertJsonPath('data.extracted.total', '24.40')
            ->assertJsonPath('data.extracted.currency', 'ILS')
            ->assertJsonPath('data.extracted.date', '2026-09-15')
            ->assertJsonPath('data.extracted.suggested_category_id', $groceries);
    }

    public function test_merchant_history_beats_keywords(): void
    {
        $account = $this->account($this->user, ['currency' => 'ILS']);
        $food = $this->user->categories()->where('default_key', 'food')->value('id');
        $this->postJson('/api/v1/transactions', [
            'type' => 'expense', 'account_id' => $account->id, 'category_id' => $food,
            'amount' => '10', 'occurred_at' => '2026-09-01T10:00:00Z', 'merchant' => 'bravo supermarket',
        ])->assertCreated();

        $id = $this->upload();

        $this->getJson("/api/v1/receipts/{$id}")->assertJsonPath('data.extracted.suggested_category_id', $food);
    }

    public function test_confirm_creates_linked_transaction_once(): void
    {
        $account = $this->account($this->user, ['currency' => 'ILS', 'opening_balance' => 10000]);
        $id = $this->upload();
        $groceries = $this->user->categories()->where('default_key', 'groceries')->value('id');
        $payload = ['type' => 'expense', 'account_id' => $account->id, 'category_id' => $groceries, 'amount' => '24.40', 'occurred_at' => '2026-09-15T18:42:00Z', 'merchant' => 'Bravo Supermarket'];

        $transactionId = $this->postJson("/api/v1/receipts/{$id}/transaction", $payload)
            ->assertCreated()
            ->assertJsonPath('data.amount_minor', 2440)
            ->json('data.id');

        $this->assertSame($transactionId, Receipt::find($id)?->transaction_id);
        $this->assertSame(7560, $account->refresh()->balance);
        $this->postJson("/api/v1/receipts/{$id}/transaction", $payload)->assertStatus(409);
        $this->getJson("/api/v1/transactions/{$transactionId}")->assertJsonPath('data.receipt_id', $id);
    }

    public function test_confirm_validates_like_a_transaction(): void
    {
        $id = $this->upload();

        $this->postJson("/api/v1/receipts/{$id}/transaction", ['type' => 'expense'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['account_id', 'amount', 'occurred_at']);
    }

    public function test_receipts_are_private_and_deletable(): void
    {
        $id = $this->upload();
        $path = Receipt::findOrFail($id)->file_path;
        Storage::disk('local')->assertExists($path);

        $this->get("/api/v1/receipts/{$id}/image")->assertOk()->assertHeader('Content-Type', 'image/jpeg');

        $this->signIn();
        $this->getJson("/api/v1/receipts/{$id}")->assertNotFound();
        $this->get("/api/v1/receipts/{$id}/image", ['Accept' => 'application/json'])->assertNotFound();
        $this->deleteJson("/api/v1/receipts/{$id}")->assertNotFound();

        $this->signIn($this->user);
        $this->deleteJson("/api/v1/receipts/{$id}")->assertNoContent();
        Storage::disk('local')->assertMissing($path);
    }

    public function test_rejects_non_images(): void
    {
        $this->post('/api/v1/receipts', ['file' => UploadedFile::fake()->create('notes.txt', 5, 'text/plain')], ['Accept' => 'application/json'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors('file');
    }

    public function test_failed_ocr_is_reported_without_leaking_details(): void
    {
        config(['masroof.ocr.driver' => 'tesseract', 'masroof.ocr.tesseract_binary' => '/nonexistent/tesseract']);

        $id = $this->upload();

        $this->getJson("/api/v1/receipts/{$id}")
            ->assertJsonPath('data.status', 'failed')
            ->assertJsonPath('data.extracted', null)
            ->assertJsonPath('data.error', __('masroof.receipt_ocr_failed'));
    }
}
