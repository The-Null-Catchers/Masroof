<?php

namespace App\Reports;

/**
 * Format-neutral report: headline metrics plus titled tables. Writers turn it
 * into CSV, XLSX or PDF, so every format shows the same numbers.
 */
final class Report
{
    /** @var array<int, array{label: string, value: string, tone?: string}> */
    public array $metrics = [];

    /** @var array<int, ReportTable> */
    public array $tables = [];

    public function __construct(
        public readonly string $title,
        public readonly string $subtitle,
        public readonly string $locale,
        public readonly string $fileStem,
    ) {}

    public function metric(string $label, string $value, ?string $tone = null): self
    {
        $this->metrics[] = array_filter(['label' => $label, 'value' => $value, 'tone' => $tone], fn ($v) => $v !== null);

        return $this;
    }

    public function table(ReportTable $table): self
    {
        $this->tables[] = $table;

        return $this;
    }

    public function isRtl(): bool
    {
        return $this->locale === 'ar';
    }
}
