<?php

namespace App\Reports;

use OpenSpout\Common\Entity\Row;
use OpenSpout\Common\Entity\Style\Style;
use OpenSpout\Writer\CSV\Writer as CsvWriter;
use OpenSpout\Writer\XLSX\Entity\SheetView;
use OpenSpout\Writer\XLSX\Options as XlsxOptions;
use OpenSpout\Writer\XLSX\Writer as XlsxWriter;

class SpreadsheetWriter
{
    public function csv(Report $report, string $path): void
    {
        $writer = new CsvWriter;
        $writer->openToFile($path);
        // OpenSpout writes a UTF-8 BOM by default, so Excel opens Arabic text correctly.
        foreach ($report->tables as $index => $table) {
            if (count($report->tables) > 1) {
                if ($index > 0) {
                    $writer->addRow(Row::fromValues([]));
                }
                $writer->addRow(Row::fromValues([$table->title]));
            }
            $writer->addRow(Row::fromValues($table->columns));
            foreach ($table->rows as $row) {
                $writer->addRow(Row::fromValues($row));
            }
        }
        $writer->close();
    }

    public function xlsx(Report $report, string $path): void
    {
        $writer = new XlsxWriter(new XlsxOptions(DEFAULT_COLUMN_WIDTH: 20));
        $writer->openToFile($path);
        $header = new Style(fontBold: true, fontColor: 'FFFFFF', backgroundColor: '0F7A68');
        $titleStyle = new Style(fontBold: true, fontSize: 14);
        $view = (new SheetView)->withRightToLeft($report->isRtl());

        $sheet = $writer->getCurrentSheet();
        $sheet->setName($this->sheetName(__('reports.summary')));
        $sheet->setSheetView($view);
        $writer->addRow(Row::fromValuesWithStyle([$report->title], $titleStyle));
        $writer->addRow(Row::fromValues([$report->subtitle]));
        $writer->addRow(Row::fromValues([]));
        foreach ($report->metrics as $metric) {
            $writer->addRow(Row::fromValues([$metric['label'], $metric['value']]));
        }

        foreach ($report->tables as $table) {
            $sheet = $writer->addNewSheetAndMakeItCurrent();
            $sheet->setName($this->sheetName($table->title));
            $sheet->setSheetView($view);
            $writer->addRow(Row::fromValuesWithStyle($table->columns, $header));
            foreach ($table->rows as $row) {
                $writer->addRow(Row::fromValues(array_map(
                    // Plain decimal strings become real numbers so they can be summed.
                    fn ($value, int $column) => $table->isNumeric($column) && is_string($value) && preg_match('/^-?\d+(\.\d+)?$/', $value) ? (float) $value : $value,
                    $row,
                    array_keys($row),
                )));
            }
        }

        $writer->close();
    }

    /** Excel limits sheet names to 31 characters without []:*?/\ */
    private function sheetName(string $title): string
    {
        return mb_substr(str_replace(['[', ']', ':', '*', '?', '/', '\\'], ' ', $title), 0, 31);
    }
}
