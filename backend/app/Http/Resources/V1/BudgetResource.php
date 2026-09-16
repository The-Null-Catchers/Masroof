<?php

namespace App\Http\Resources\V1;

use App\Models\Budget;
use App\Services\BudgetCalculator;
use App\Support\Money;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Budget */
class BudgetResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        $progress = app(BudgetCalculator::class)->progress($this->resource, $request->user());
        $money = fn (int $minor) => Money::toDecimal($minor, $this->currency);

        return [
            'id' => $this->id,
            'name' => $this->name,
            'period' => $this->period,
            'currency' => $this->currency,
            'amount' => $money($this->amount),
            'amount_minor' => $this->amount,
            'starts_on' => $this->starts_on?->toDateString(),
            'ends_on' => $this->ends_on?->toDateString(),
            'alert_thresholds' => app(BudgetCalculator::class)->thresholds($this->resource),
            'category_ids' => $this->categories->pluck('id')->values(),
            'archived' => $this->archived_at !== null,
            'progress' => [
                ...$progress,
                'spent' => $money($progress['spent']),
                'spent_minor' => $progress['spent'],
                'remaining' => $money($progress['remaining']),
                'remaining_minor' => $progress['remaining'],
                'safe_to_spend_daily' => $money($progress['safe_to_spend_daily']),
                'safe_to_spend_daily_minor' => $progress['safe_to_spend_daily'],
                'expected_spent_minor' => $progress['expected_spent'],
                'projected_spent_minor' => $progress['projected_spent'],
            ],
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
