<?php

namespace Tests\Unit;

use App\Services\Ocr\MockOcrProvider;
use App\Services\Ocr\ReceiptParser;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class ReceiptParserTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        $this->travelTo(Carbon::parse('2026-09-17 10:00', 'UTC'));
    }

    public function test_english_receipt(): void
    {
        $result = (new ReceiptParser)->parse(MockOcrProvider::SAMPLE, 'USD');

        $this->assertSame('Bravo Supermarket', $result['merchant']);
        $this->assertSame(2440, $result['total']);
        $this->assertSame('24.40', $result['total_decimal']);
        $this->assertSame('ILS', $result['currency']);
        $this->assertSame('2026-09-15', $result['date']);
        $this->assertSame(1.0, $result['confidence']);
    }

    public function test_arabic_receipt_with_arabic_digits_and_dinar(): void
    {
        $text = "مطعم الريم\nعمّان - شارع الجامعة\nالتاريخ ١٠/٠٩/٢٠٢٦\nمنسف  ٨٫٥٠٠\nالمجموع الفرعي ٩٫٠٠٠\nالإجمالي ١٠٫٢٥٠ دينار\nشكرًا لزيارتكم";
        $result = (new ReceiptParser)->parse($text, 'ILS');

        $this->assertSame('مطعم الريم', $result['merchant']);
        $this->assertSame('JOD', $result['currency']);
        $this->assertSame(10250, $result['total']);
        $this->assertSame('2026-09-10', $result['date']);
    }

    public function test_unreadable_text_falls_back_gracefully(): void
    {
        $result = (new ReceiptParser)->parse("~~ ## ~~\n", 'EUR');

        $this->assertNull($result['total']);
        $this->assertNull($result['date']);
        $this->assertSame('EUR', $result['currency']);
        $this->assertLessThan(0.5, $result['confidence']);
    }

    public function test_future_dates_are_ignored(): void
    {
        $result = (new ReceiptParser)->parse("Shop\n01/12/2026\nTotal 5.00", 'USD');

        $this->assertNull($result['date']);
        $this->assertSame(500, $result['total']);
    }
}
