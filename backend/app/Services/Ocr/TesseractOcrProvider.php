<?php

namespace App\Services\Ocr;

use Illuminate\Support\Facades\Process;

/**
 * Free, fully local OCR using the Tesseract CLI with Arabic and English models.
 */
class TesseractOcrProvider implements OcrProvider
{
    public function __construct(
        private readonly string $binary = 'tesseract',
        private readonly string $languages = 'ara+eng',
    ) {}

    public function name(): string
    {
        return 'tesseract';
    }

    public function recognize(string $absolutePath, string $mimeType): string
    {
        if (! str_starts_with($mimeType, 'image/')) {
            throw new OcrException('Tesseract only reads images.');
        }

        try {
            $result = Process::timeout(60)->run([$this->binary, $absolutePath, 'stdout', '-l', $this->languages, '--psm', '4']);
        } catch (\Throwable $e) {
            throw new OcrException($e->getMessage(), previous: $e);
        }

        if (! $result->successful()) {
            throw new OcrException(trim($result->errorOutput()) ?: 'Tesseract failed.');
        }

        return $result->output();
    }
}
