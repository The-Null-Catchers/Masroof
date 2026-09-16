<?php

namespace App\Http\Resources\V1;

use App\Models\RecurringTransaction;
use App\Services\RecurrenceSchedule;
use App\Support\Money;
use Carbon\CarbonImmutable;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin RecurringTransaction */
class RecurringTransactionResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        $schedule = app(RecurrenceSchedule::class);
        $upcoming = [];
        $next = $this->next_occurrence_on ? CarbonImmutable::parse($this->next_occurrence_on->toDateString()) : null;
        while ($next !== null && count($upcoming) < 3) {
            $upcoming[] = $next->toDateString();
            $next = $schedule->nextOnOrAfter($this->resource, $next->addDay());
        }

        return [
            'id' => $this->id,
            'name' => $this->name,
            'type' => $this->type->value,
            'account_id' => $this->account_id,
            'category_id' => $this->category_id,
            'transfer_account_id' => $this->transfer_account_id,
            'currency' => $this->currency,
            'amount' => Money::toDecimal($this->amount, $this->currency),
            'amount_minor' => $this->amount,
            'transfer_amount_minor' => $this->transfer_amount,
            'merchant' => $this->merchant,
            'payment_method' => $this->payment_method,
            'note' => $this->note,
            'frequency' => $this->frequency,
            'interval' => $this->interval,
            'starts_on' => $this->starts_on->toDateString(),
            'ends_on' => $this->ends_on?->toDateString(),
            'next_occurrence_on' => $this->next_occurrence_on?->toDateString(),
            'upcoming' => $upcoming,
            'mode' => $this->mode,
            'remind_days_before' => $this->remind_days_before,
            'paused' => $this->paused_at !== null,
            'category' => $this->whenLoaded('category', fn () => $this->category ? [
                'id' => $this->category->id, 'name' => $this->category->name, 'default_key' => $this->category->default_key,
                'icon' => $this->category->icon, 'color' => $this->category->color,
            ] : null),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
