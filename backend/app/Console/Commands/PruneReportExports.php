<?php

namespace App\Console\Commands;

use App\Models\ReportExport;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;

#[Signature('masroof:prune-exports')]
#[Description('Delete expired report export files')]
class PruneReportExports extends Command
{
    public function handle(): int
    {
        $count = 0;
        ReportExport::query()->where('expires_at', '<', now())->lazyById()->each(function (ReportExport $export) use (&$count) {
            if ($export->file_path) {
                Storage::disk('local')->delete($export->file_path);
            }
            $export->delete();
            $count++;
        });
        $this->info("Pruned {$count} export(s).");

        return self::SUCCESS;
    }
}
