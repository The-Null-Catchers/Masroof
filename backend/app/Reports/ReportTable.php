<?php

namespace App\Reports;

final class ReportTable
{
    /** @var array<int, array<int, string|int|float|null>> */
    public array $rows = [];

    /**
     * @param  array<int, string>  $columns
     * @param  array<int, bool>  $numeric  Columns aligned as numbers.
     */
    public function __construct(
        public readonly string $title,
        public readonly array $columns,
        public readonly array $numeric = [],
        public readonly ?string $emptyText = null,
    ) {}

    /** @param array<int, string|int|float|null> $cells */
    public function row(array $cells): self
    {
        $this->rows[] = $cells;

        return $this;
    }

    public function isNumeric(int $column): bool
    {
        return $this->numeric[$column] ?? false;
    }
}
