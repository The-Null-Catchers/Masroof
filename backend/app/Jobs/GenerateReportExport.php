<?php

namespace App\Jobs;

use App\Models\ReportExport;
use App\Reports\PdfWriter;
use App\Reports\ReportBuilder;
use App\Reports\SpreadsheetWriter;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Throwable;

class GenerateReportExport implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 2;

    public int $timeout = 300;

    public function __construct(public readonly string $exportId) {}

    public function handle(ReportBuilder $builder, SpreadsheetWriter $spreadsheets, PdfWriter $pdf): void
    {
        $export = ReportExport::query()->with('user')->find($this->exportId);
        if ($export === null || $export->status === 'completed') {
            return;
        }
        $export->update(['status' => 'processing']);

        $disk = Storage::disk('local');
        $relative = "exports/{$export->user_id}/{$export->id}.{$export->format}";
        $disk->makeDirectory(dirname($relative));
        $absolute = $disk->path($relative);

        $report = $builder->build($export->user, $export->type, $export->parameters);
        match ($export->format) {
            'csv' => $spreadsheets->csv($report, $absolute),
            'xlsx' => $spreadsheets->xlsx($report, $absolute),
            default => $pdf->write($report, $absolute),
        };

        $export->update([
            'status' => 'completed',
            'file_path' => $relative,
            'file_name' => Str::slug($report->fileStem).'-'.now($export->user->timezone)->format('Y-m-d').".{$export->format}",
            'size' => $disk->size($relative),
            'completed_at' => now(),
            'expires_at' => now()->addDays(7),
        ]);
    }

    public function failed(Throwable $exception): void
    {
        Log::error('Report export failed', ['export_id' => $this->exportId, 'error' => $exception->getMessage()]);
        ReportExport::query()->whereKey($this->exportId)->update(['status' => 'failed', 'error' => mb_substr(__('masroof.export_failed'), 0, 255)]);
    }
}
