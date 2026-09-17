<?php

namespace App\Services\Ocr;

/**
 * Development/test provider that needs no OCR engine. It returns the text of
 * a sidecar file ("receipt.jpg.txt") when present, otherwise a sample receipt.
 */
class MockOcrProvider implements OcrProvider
{
    public const SAMPLE = <<<'TXT'
        Bravo Supermarket
        Ramallah - Al Masyoun
        Date: 15/09/2026 18:42
        Milk 1L            7.50
        Bread              4.00
        Tomatoes 2kg      12.90
        Subtotal          24.40
        TOTAL (NIS)       24.40
        Thank you!
        TXT;

    public function name(): string
    {
        return 'mock';
    }

    public function recognize(string $absolutePath, string $mimeType): string
    {
        $sidecar = $absolutePath.'.txt';

        return is_file($sidecar) ? (string) file_get_contents($sidecar) : self::SAMPLE;
    }
}
