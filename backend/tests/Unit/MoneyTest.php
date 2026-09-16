<?php

namespace Tests\Unit;

use App\Support\Money;
use InvalidArgumentException;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

class MoneyTest extends TestCase
{
    /** @return array<string, array{string, string, int}> */
    public static function conversions(): array
    {
        return [
            'whole SAR' => ['10', 'SAR', 1000],
            'one decimal' => ['10.5', 'SAR', 1050],
            'two decimals' => ['0.07', 'SAR', 7],
            'KWD three decimals' => ['1.234', 'KWD', 1234],
            'JPY no decimals' => ['1500', 'JPY', 1500],
            'negative' => ['-25.10', 'SAR', -2510],
            'large' => ['999999999.99', 'SAR', 99999999999],
            'float trap' => ['0.29', 'USD', 29],
        ];
    }

    #[DataProvider('conversions')]
    public function test_it_converts_decimal_strings_to_minor_units(string $decimal, string $currency, int $minor): void
    {
        $this->assertSame($minor, Money::toMinor($decimal, $currency));
    }

    public function test_it_formats_minor_units_as_decimal_strings(): void
    {
        $this->assertSame('10.50', Money::toDecimal(1050, 'SAR'));
        $this->assertSame('0.07', Money::toDecimal(7, 'SAR'));
        $this->assertSame('-0.05', Money::toDecimal(-5, 'SAR'));
        $this->assertSame('1.234', Money::toDecimal(1234, 'KWD'));
        $this->assertSame('0.001', Money::toDecimal(1, 'BHD'));
        $this->assertSame('1500', Money::toDecimal(1500, 'JPY'));
    }

    public function test_it_rejects_too_many_decimals(): void
    {
        $this->expectException(InvalidArgumentException::class);
        Money::toMinor('1.234', 'SAR');
    }

    public function test_it_rejects_non_numeric_input(): void
    {
        $this->expectException(InvalidArgumentException::class);
        Money::toMinor('1e5', 'SAR');
    }

    public function test_it_rejects_unsupported_currencies(): void
    {
        $this->expectException(InvalidArgumentException::class);
        Money::exponent('XYZ');
    }
}
