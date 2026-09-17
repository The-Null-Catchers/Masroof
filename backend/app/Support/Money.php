<?php

namespace App\Support;

use InvalidArgumentException;

/**
 * Exact conversions between decimal strings and integer minor units.
 * Never uses floating point arithmetic.
 */
final class Money
{
    /** Converts Arabic-Indic and Eastern Arabic-Indic digits to ASCII. */
    public static function normalizeDigits(string $text): string
    {
        return strtr($text, [
            '٠' => '0', '١' => '1', '٢' => '2', '٣' => '3', '٤' => '4', '٥' => '5', '٦' => '6', '٧' => '7', '٨' => '8', '٩' => '9',
            '۰' => '0', '۱' => '1', '۲' => '2', '۳' => '3', '۴' => '4', '۵' => '5', '۶' => '6', '۷' => '7', '۸' => '8', '۹' => '9',
        ]);
    }

    public static function exponent(string $currency): int
    {
        $currencies = config('masroof.currencies');

        if (! array_key_exists($currency, $currencies)) {
            throw new InvalidArgumentException("Unsupported currency [{$currency}].");
        }

        return $currencies[$currency];
    }

    public static function isSupported(string $currency): bool
    {
        return array_key_exists($currency, config('masroof.currencies'));
    }

    /**
     * Pattern for a non-negative decimal with at most `$exponent` fractional digits.
     */
    public static function pattern(int $exponent, bool $allowNegative = false): string
    {
        $sign = $allowNegative ? '-?' : '';
        $fraction = $exponent > 0 ? '(\.\d{1,'.$exponent.'})?' : '';

        return '/^'.$sign.'\d{1,15}'.$fraction.'$/';
    }

    public static function toMinor(string|int $amount, string $currency): int
    {
        $amount = trim((string) $amount);
        $exponent = self::exponent($currency);

        if (! preg_match(self::pattern($exponent, true), $amount)) {
            throw new InvalidArgumentException("Invalid amount [{$amount}] for {$currency}.");
        }

        $negative = str_starts_with($amount, '-');
        $amount = ltrim($amount, '-');
        [$whole, $fraction] = array_pad(explode('.', $amount, 2), 2, '');
        $minor = (int) ($whole.str_pad($fraction, $exponent, '0'));

        return $negative ? -$minor : $minor;
    }

    private const SYMBOLS = ['ILS' => '₪', 'USD' => '$', 'EUR' => '€', 'GBP' => '£'];

    private const ARABIC_SYMBOLS = [
        'JOD' => 'د.أ', 'SAR' => 'ر.س', 'AED' => 'د.إ', 'KWD' => 'د.ك', 'BHD' => 'د.ب', 'OMR' => 'ر.ع',
        'QAR' => 'ر.ق', 'EGP' => 'ج.م', 'IQD' => 'د.ع', 'MAD' => 'د.م', 'TND' => 'د.ت', 'DZD' => 'د.ج', 'LBP' => 'ل.ل',
    ];

    /**
     * Human readable amount for messages, e.g. "₪ 1,250.50" or "1,250.500 د.أ".
     * Unicode isolates keep the number intact inside right-to-left sentences.
     */
    public static function display(int $minor, string $currency, ?string $locale = null): string
    {
        $locale ??= app()->getLocale();
        $decimal = self::toDecimal(abs($minor), $currency);
        [$whole, $fraction] = array_pad(explode('.', $decimal, 2), 2, null);
        $number = ($minor < 0 ? '-' : '').number_format((int) $whole).($fraction !== null ? '.'.$fraction : '');
        $arabic = str_starts_with($locale, 'ar');
        $symbol = self::SYMBOLS[$currency] ?? ($arabic ? (self::ARABIC_SYMBOLS[$currency] ?? $currency) : $currency);
        $isolated = "\u{2066}{$number}\u{2069}";

        return $arabic ? "{$isolated} {$symbol}" : "{$symbol} {$isolated}";
    }

    public static function toDecimal(int $minor, string $currency): string
    {
        $exponent = self::exponent($currency);
        $negative = $minor < 0;
        $digits = str_pad((string) abs($minor), $exponent + 1, '0', STR_PAD_LEFT);

        $result = $exponent === 0
            ? $digits
            : substr($digits, 0, -$exponent).'.'.substr($digits, -$exponent);

        return ($negative ? '-' : '').$result;
    }
}
