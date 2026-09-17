<?php

namespace App\Reports;

use Mpdf\Config\ConfigVariables;
use Mpdf\Config\FontVariables;
use Mpdf\Mpdf;
use Mpdf\Output\Destination;

/**
 * Branded A4 PDF. mPDF shapes Arabic glyphs and lays out RTL correctly with
 * the bundled IBM Plex Sans Arabic font.
 */
class PdfWriter
{
    public function write(Report $report, string $path): void
    {
        $tempDir = storage_path('framework/cache/mpdf');
        if (! is_dir($tempDir)) {
            mkdir($tempDir, 0775, true);
        }

        $defaultFonts = (new FontVariables)->getDefaults();
        $mpdf = new Mpdf([
            'mode' => 'utf-8',
            'format' => 'A4',
            'margin_top' => 16,
            'margin_bottom' => 18,
            'margin_left' => 14,
            'margin_right' => 14,
            'tempDir' => $tempDir,
            'fontDir' => [...(new ConfigVariables)->getDefaults()['fontDir'], resource_path('fonts')],
            'fontdata' => $defaultFonts['fontdata'] + [
                'plexarabic' => [
                    'R' => 'IBMPlexSansArabic-Regular.ttf',
                    'B' => 'IBMPlexSansArabic-Bold.ttf',
                    'useOTL' => 0xFF,
                    'useKashida' => 75,
                ],
            ],
            'default_font' => 'plexarabic',
        ]);

        $mpdf->SetTitle($report->title);
        $mpdf->SetAuthor('Masroof');
        $mpdf->SetCreator('Masroof');
        if ($report->isRtl()) {
            $mpdf->SetDirectionality('rtl');
        }
        $mpdf->SetHTMLFooter(view('reports.footer', ['report' => $report])->render());
        $mpdf->WriteHTML(view('reports.pdf', [
            'report' => $report,
            'logo' => 'data:image/png;base64,'.base64_encode((string) file_get_contents(resource_path('views/reports/logo.png'))),
        ])->render());
        $mpdf->Output($path, Destination::FILE);
    }
}
