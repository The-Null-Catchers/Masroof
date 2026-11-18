<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Tests\TestCase;

class PortfolioMonthTest extends TestCase
{
    use RefreshDatabase;

    public function test_arabic_month_keeps_balances_consistent_after_receipt_review_and_transfer_replay(): void
    {
        Storage::fake('local');
        config(['masroof.ocr.driver' => 'mock']);
        $this->travelTo(Carbon::parse('2026-09-16 09:00', 'UTC'));
        $user = $this->signIn(User::factory()->create(['timezone' => 'Asia/Hebron', 'locale' => 'ar', 'currency' => 'ILS']));
        $bank = $this->account($user, ['name' => 'الحساب البنكي', 'type' => 'bank', 'currency' => 'ILS']);
        $wallet = $this->account($user, ['name' => 'المحفظة', 'type' => 'cash', 'currency' => 'ILS']);
        $food = $this->category($user, 'expense', ['name' => 'المشتريات']);
        $salary = $this->category($user, 'income', ['name' => 'الراتب']);
        $this->withHeader('Accept-Language', 'ar');

        $budget = $this->postJson('/api/v1/budgets', [
            'name' => 'ميزانية المشتريات', 'period' => 'monthly', 'currency' => 'ILS', 'amount' => '80.00',
            'category_ids' => [$food->id], 'alert_thresholds' => [100],
        ])->assertCreated()->json('data.id');
        $this->postJson('/api/v1/transactions', [
            'type' => 'income', 'account_id' => $bank->id, 'category_id' => $salary->id,
            'amount' => '5200.00', 'occurred_at' => '2026-09-01T08:00:00Z',
        ])->assertCreated();

        $transfer = [
            'id' => (string) Str::ulid(), 'type' => 'transfer', 'account_id' => $bank->id,
            'transfer_account_id' => $wallet->id, 'amount' => '500.00',
            'occurred_at' => '2026-09-02T08:00:00Z',
        ];
        $this->postJson('/api/v1/transactions', $transfer)->assertCreated();
        $this->postJson('/api/v1/transactions', $transfer)->assertOk()->assertJsonPath('data.id', $transfer['id']);
        $this->assertSame(470_000, $bank->refresh()->balance);
        $this->assertSame(50_000, $wallet->refresh()->balance);

        $receipt = $this->post('/api/v1/receipts', [
            'file' => UploadedFile::fake()->image('synthetic-receipt.jpg', 600, 900),
        ], ['Accept' => 'application/json'])->assertAccepted()->json('data.id');
        $this->getJson("/api/v1/receipts/{$receipt}")->assertOk()
            ->assertJsonPath('data.provider', 'mock')
            ->assertJsonPath('data.extracted.total', '24.40')
            ->assertJsonPath('data.transaction_id', null);
        $this->assertSame(50_000, $wallet->refresh()->balance);

        $expense = [
            'type' => 'expense', 'account_id' => $wallet->id, 'category_id' => $food->id,
            'amount' => '84.75', 'occurred_at' => '2026-09-15T16:00:00Z', 'merchant' => 'بقالة الحي',
        ];
        $this->postJson("/api/v1/receipts/{$receipt}/transaction", $expense)->assertCreated()
            ->assertJsonPath('data.amount_minor', 8475);
        $this->postJson("/api/v1/receipts/{$receipt}/transaction", $expense)->assertConflict();
        $this->assertSame(41_525, $wallet->refresh()->balance);
        $this->assertSame(470_000, $bank->refresh()->balance);
        $this->getJson("/api/v1/budgets/{$budget}")->assertOk()
            ->assertJsonPath('data.progress.spent', '84.75')
            ->assertJsonPath('data.progress.remaining', '-4.75')
            ->assertJsonPath('data.progress.status', 'exceeded');
        $this->getJson('/api/v1/reports/summary?from=2026-09-01&to=2026-09-30')->assertOk()
            ->assertJsonPath('data.totals.0.currency', 'ILS')
            ->assertJsonPath('data.totals.0.income', '5200.00')
            ->assertJsonPath('data.totals.0.expense', '84.75')
            ->assertJsonPath('data.totals.0.net', '5115.25')
            ->assertJsonPath('data.totals.0.count', 2);

        $export = $this->postJson('/api/v1/reports/exports', [
            'type' => 'monthly', 'format' => 'pdf', 'from' => '2026-09-01', 'to' => '2026-09-30',
        ])->assertAccepted()->assertJsonPath('data.status', 'completed')->json('data.id');
        $pdf = $this->get("/api/v1/reports/exports/{$export}/download")->assertOk()
            ->assertHeader('Content-Type', 'application/pdf')->streamedContent();
        $this->assertStringStartsWith('%PDF-', $pdf);
        $this->assertGreaterThan(5_000, strlen($pdf));

        $evidence = getenv('MASROOF_PORTFOLIO_PDF');
        if ($evidence !== false && $evidence !== '') {
            $this->assertSame(strlen($pdf), file_put_contents($evidence, $pdf));
        }
    }
}
