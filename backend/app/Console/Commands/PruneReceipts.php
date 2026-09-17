<?php

namespace App\Console\Commands;

use App\Models\Receipt;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;

#[Signature('masroof:prune-receipts {--days=7 : Age of abandoned scans to delete}')]
#[Description('Delete receipt photos that were scanned but never saved as a transaction')]
class PruneReceipts extends Command
{
    public function handle(): int
    {
        $count = 0;
        Receipt::query()
            ->whereNull('transaction_id')
            ->where('created_at', '<', now()->subDays((int) $this->option('days')))
            ->lazyById()
            ->each(function (Receipt $receipt) use (&$count) {
                Storage::disk('local')->delete($receipt->file_path);
                $receipt->delete();
                $count++;
            });
        $this->info("Pruned {$count} receipt(s).");

        return self::SUCCESS;
    }
}
