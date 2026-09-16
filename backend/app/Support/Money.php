<?php

namespace App\Support;

use InvalidArgumentException;

/**
 * Exact conversions between decimal strings and integer minor units.
 * Never uses floating point arithmetic.
 */
final class Money
{
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
