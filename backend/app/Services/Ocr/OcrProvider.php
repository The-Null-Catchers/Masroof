<?php

namespace App\Services\Ocr;

/**
 * Text recognition backend. Implementations must be side-effect free and
 * return plain text with line breaks preserved. Add a cloud provider by
 * implementing this interface and registering it in config/masroof.php.
 */
interface OcrProvider
{
    public function name(): string;

    /** @throws OcrException */
    public function recognize(string $absolutePath, string $mimeType): string;
}
