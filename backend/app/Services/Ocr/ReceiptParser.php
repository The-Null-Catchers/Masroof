<?php

namespace App\Services\Ocr;

use App\Support\Money;
use Carbon\CarbonImmutable;

/**
 * Deterministic extraction of merchant, total, date and currency from OCR
 * text in Arabic or English. Designed to degrade gracefully: every field may
 * be null and the user always reviews the result before saving.
 */
class ReceiptParser
{
    private const TOTAL_KEYWORDS = [
        'grand total', 'total due', 'amount due', 'total', 'balance due', 'to pay',
        'المجموع الكلي', 'الإجمالي', 'الاجمالي', 'المجموع', 'المبلغ الإجمالي', 'الصافي', 'المطلوب',
    ];

    private const SKIP_FOR_TOTAL = ['subtotal', 'sub total', 'sub-total', 'tax', 'vat', 'discount', 'change', 'cash', 'الضريبة', 'الخصم', 'الباقي', 'المجموع الفرعي'];

    private const CURRENCY_HINTS = [
        'ILS' => ['₪', 'ils', 'nis', 'شيكل', 'شاقل', 'ش.ج'],
        'JOD' => ['jod', 'jd', 'دينار', 'د.أ', 'د.ا'],
        'USD' => ['$', 'usd', 'دولار'],
        'EUR' => ['€', 'eur', 'يورو'],
        'SAR' => ['sar', 'ريال', 'ر.س'],
        'EGP' => ['egp', 'جنيه', 'ج.م'],
    ];

    /**
     * @return array{merchant: string|null, total: int|null, total_decimal: string|null, currency: string, date: string|null, confidence: float}
     */
    public function parse(string $text, string $fallbackCurrency): array
    {
        $normalized = Money::normalizeDigits($text);
        $normalized = str_replace(['٫', '٬'], ['.', ','], $normalized);
        $lines = array_values(array_filter(array_map(fn ($l) => trim(preg_replace('/\s+/u', ' ', $l) ?? ''), preg_split('/\R/u', $normalized) ?: [])));

        $currency = $this->currency($normalized) ?? $fallbackCurrency;
        $total = $this->total($lines, $currency);
        $merchant = $this->merchant($lines);
        $date = $this->date($normalized);

        $found = count(array_filter([$merchant, $total, $date]));

        return [
            'merchant' => $merchant,
            'total' => $total,
            'total_decimal' => $total === null ? null : Money::toDecimal($total, $currency),
            'currency' => $currency,
            'date' => $date,
            'confidence' => round($found / 3, 2),
        ];
    }

    private function currency(string $text): ?string
    {
        $lower = mb_strtolower($text);
        foreach (self::CURRENCY_HINTS as $code => $hints) {
            foreach ($hints as $hint) {
                $pattern = preg_match('/^[a-z]+$/', $hint) ? '/\b'.preg_quote($hint, '/').'\b/u' : '/'.preg_quote($hint, '/').'/u';
                if (preg_match($pattern, $lower)) {
                    return $code;
                }
            }
        }

        return null;
    }

    /** @param array<int, string> $lines */
    private function total(array $lines, string $currency): ?int
    {
        $amountPattern = '/(\d{1,3}(?:,\d{3})+(?:\.\d{1,3})?|\d+(?:\.\d{1,3})?)/';
        $candidates = [];

        foreach ($lines as $index => $line) {
            $lower = mb_strtolower($line);
            $isSkipped = $this->containsAny($lower, self::SKIP_FOR_TOTAL);
            $isTotal = ! $isSkipped && $this->containsAny($lower, self::TOTAL_KEYWORDS);

            if (! preg_match_all($amountPattern, $line, $matches)) {
                continue;
            }
            $values = array_values(array_filter(array_map(fn ($m) => $this->toMinor($m, $currency), $matches[1]), fn ($v) => $v !== null && $v > 0));
            if ($values === [] || $this->looksLikeDateOrPhone($line)) {
                continue;
            }
            $value = end($values);

            if ($isTotal) {
                // The last explicit total on the receipt wins (e.g. after discounts).
                $candidates['total'] = $value;
            } elseif (! $isSkipped) {
                $candidates['max'] = max($candidates['max'] ?? 0, $value);
            }
        }

        return $candidates['total'] ?? ($candidates['max'] ?? null) ?: null;
    }

    /** @param array<int, string> $lines */
    private function merchant(array $lines): ?string
    {
        foreach (array_slice($lines, 0, 5) as $line) {
            $letters = preg_match_all('/\p{L}/u', $line);
            $digits = preg_match_all('/\d/', $line);
            if ($letters >= 3 && $letters > $digits && ! $this->containsAny(mb_strtolower($line), ['receipt', 'invoice', 'فاتورة', 'إيصال', 'tel', 'هاتف', 'www', 'date'])) {
                return mb_substr($line, 0, 120);
            }
        }

        return null;
    }

    private function date(string $text): ?string
    {
        $patterns = [
            '/\b(\d{4})[-\/.](\d{1,2})[-\/.](\d{1,2})\b/' => fn ($m) => [$m[1], $m[2], $m[3]],
            '/\b(\d{1,2})[-\/.](\d{1,2})[-\/.](\d{4})\b/' => fn ($m) => [$m[3], $m[2], $m[1]],
            '/\b(\d{1,2})[-\/.](\d{1,2})[-\/.](\d{2})\b/' => fn ($m) => ['20'.$m[3], $m[2], $m[1]],
        ];
        foreach ($patterns as $pattern => $order) {
            if (preg_match($pattern, $text, $m)) {
                [$y, $mo, $d] = array_map('intval', $order($m));
                if (checkdate($mo, $d, $y) && $y >= 2000) {
                    $date = CarbonImmutable::create($y, $mo, $d);
                    // Receipts from the future are OCR noise.
                    if ($date !== null && $date->lte(CarbonImmutable::now()->addDay())) {
                        return $date->toDateString();
                    }
                }
            }
        }

        return null;
    }

    private function toMinor(string $value, string $currency): ?int
    {
        $plain = str_replace(',', '', $value);
        $exp = Money::exponent($currency);
        if (preg_match('/\.(\d+)$/', $plain, $m) && strlen($m[1]) > $exp) {
            return null;
        }

        return preg_match(Money::pattern($exp), $plain) ? Money::toMinor($plain, $currency) : null;
    }

    private function looksLikeDateOrPhone(string $line): bool
    {
        return (bool) preg_match('/\d{1,4}[\/\-]\d{1,2}[\/\-]\d{2,4}|\d{2}:\d{2}|\+?\d{7,}/', $line)
            && ! $this->containsAny(mb_strtolower($line), self::TOTAL_KEYWORDS);
    }

    /** @param array<int, string> $needles */
    private function containsAny(string $haystack, array $needles): bool
    {
        foreach ($needles as $needle) {
            if (str_contains($haystack, $needle)) {
                return true;
            }
        }

        return false;
    }
}
