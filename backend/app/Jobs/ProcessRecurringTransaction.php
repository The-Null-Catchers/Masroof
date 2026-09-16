<?php

namespace App\Jobs;

use App\Models\RecurringTransaction;
use App\Services\RecurringService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldBeUnique;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class ProcessRecurringTransaction implements ShouldBeUnique, ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;

    /** @var array<int, int> */
    public array $backoff = [60, 300];

    public function __construct(public readonly string $ruleId) {}

    public function uniqueId(): string
    {
        return $this->ruleId;
    }

    public function handle(RecurringService $service): void
    {
        $rule = RecurringTransaction::query()->find($this->ruleId);
        if ($rule !== null) {
            $service->process($rule);
        }
    }
}
