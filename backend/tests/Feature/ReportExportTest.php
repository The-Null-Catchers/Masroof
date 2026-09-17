<?php

namespace Tests\Feature;

use App\Models\ReportExport;
use App\Models\User;
use App\Services\TransactionService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Routing\Middleware\ThrottleRequests;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Storage;
use OpenSpout\Reader\XLSX\Reader as XlsxReader;
use Tests\TestCase;

class ReportExportTest extends TestCase
{
    use RefreshDatabase;

    private User $user;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('local');
        $this->travelTo(Carbon::parse('2026-09-16 09:00', 'UTC'));
        $this->user = $this->signIn(User::factory()->create(['timezone' => 'Asia/Hebron', 'currency' => 'ILS', 'locale' => 'en']));
        $wallet = $this->account($this->user, ['currency' => 'ILS', 'name' => 'Wallet', 'opening_balance' => 1_000_00]);
        $food = $this->category($this->user, 'expense', ['name' => 'Restaurants']);
        $salary = $this->category($this->user, 'income', ['name' => 'Salary']);
        $service = app(TransactionService::class);
        $service->create($this->user, ['type' => 'income', 'account_id' => $wallet->id, 'category_id' => $salary->id, 'amount' => 5_000_00, 'occurred_at' => Carbon::parse('2026-09-01 08:00', 'UTC'), 'merchant' => 'Payroll']);
        $service->create($this->user, ['type' => 'expense', 'account_id' => $wallet->id, 'category_id' => $food->id, 'amount' => 42_50, 'occurred_at' => Carbon::parse('2026-09-05 12:00', 'UTC'), 'merchant' => 'مطعم الزيتونة', 'tags' => ['friends']]);
    }

    private function export(array $payload): ReportExport
    {
        $id = $this->postJson('/api/v1/reports/exports', $payload)->assertAccepted()->json('data.id');

        return ReportExport::query()->findOrFail($id);
    }

    public function test_transactions_csv_contains_exact_amounts_and_arabic_text(): void
    {
        $export = $this->export(['type' => 'transactions', 'format' => 'csv', 'from' => '2026-09-01', 'to' => '2026-09-30']);

        $this->getJson("/api/v1/reports/exports/{$export->id}")->assertJsonPath('data.status', 'completed');
        $csv = $this->get("/api/v1/reports/exports/{$export->id}/download")->assertOk()->streamedContent();

        $this->assertStringStartsWith("\u{FEFF}", $csv);
        $this->assertStringContainsString('Date,Type,Description,Category,Account,Amount,Currency,Tags,Note', $csv);
        $this->assertStringContainsString('"مطعم الزيتونة",Restaurants,Wallet,-42.50,ILS,friends', $csv);
        $this->assertStringContainsString('5000.00', $csv);
        $this->assertSame('transactions-2026-09-16.csv', $export->refresh()->file_name);
    }

    public function test_monthly_xlsx_has_summary_and_section_sheets_rtl_in_arabic(): void
    {
        $id = $this->withHeader('Accept-Language', 'ar')
            ->postJson('/api/v1/reports/exports', ['type' => 'monthly', 'format' => 'xlsx'])
            ->assertAccepted()->json('data.id');
        $export = ReportExport::query()->findOrFail($id);

        $path = Storage::disk('local')->path($export->file_path);
        $reader = new XlsxReader;
        $reader->open($path);
        $sheets = [];
        foreach ($reader->getSheetIterator() as $sheet) {
            $rows = [];
            foreach ($sheet->getRowIterator() as $row) {
                $rows[] = $row->toArray();
            }
            $sheets[$sheet->getName()] = $rows;
        }
        $reader->close();

        $this->assertArrayHasKey('الملخص', $sheets);
        $this->assertSame('التقرير المالي الشهري', $sheets['الملخص'][0][0]);
        $this->assertArrayHasKey('المصروفات حسب الفئة', $sheets);
        $this->assertMatchesRegularExpression('/rightToLeft="(1|true)"/', (string) file_get_contents('zip://'.$path.'#xl/worksheets/sheet1.xml'));
    }

    public function test_pdf_reports_render_in_both_languages(): void
    {
        foreach (['en' => 'monthly', 'ar' => 'budgets'] as $locale => $type) {
            $id = $this->withHeader('Accept-Language', $locale)
                ->postJson('/api/v1/reports/exports', ['type' => $type, 'format' => 'pdf'])
                ->assertAccepted()->json('data.id');
            $export = ReportExport::query()->findOrFail($id);

            $this->assertSame('completed', $export->status);
            $pdf = Storage::disk('local')->get($export->file_path);
            $this->assertStringStartsWith('%PDF-', $pdf);
            $this->assertGreaterThan(5_000, strlen($pdf));
        }
    }

    public function test_every_report_type_and_format_generates(): void
    {
        // The endpoint is rate limited for users; this test exercises every format at once.
        $this->withoutMiddleware(ThrottleRequests::class);
        foreach (ReportExport::FORMATS as $type => $formats) {
            foreach ($formats as $format) {
                $export = $this->export(['type' => $type, 'format' => $format]);
                $this->assertSame('completed', $export->status, "{$type}.{$format}");
                Storage::disk('local')->assertExists($export->file_path);
            }
        }
    }

    public function test_validation_ownership_and_pruning(): void
    {
        $this->postJson('/api/v1/reports/exports', ['type' => 'monthly', 'format' => 'csv'])->assertUnprocessable()->assertJsonValidationErrors('format');
        $this->postJson('/api/v1/reports/exports', ['type' => 'secrets', 'format' => 'pdf'])->assertUnprocessable()->assertJsonValidationErrors('type');

        $export = $this->export(['type' => 'categories', 'format' => 'csv']);
        $this->getJson('/api/v1/reports/exports')->assertJsonCount(1, 'data');

        $this->signIn();
        $this->getJson("/api/v1/reports/exports/{$export->id}")->assertNotFound();
        $this->get("/api/v1/reports/exports/{$export->id}/download")->assertNotFound();

        $this->travel(8)->days();
        $this->artisan('masroof:prune-exports')->assertSuccessful();
        Storage::disk('local')->assertMissing($export->file_path);
        $this->assertModelMissing($export);
    }
}
