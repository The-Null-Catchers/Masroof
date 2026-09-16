<?php

namespace App\Http\Resources\V1;

use App\Models\Goal;
use App\Services\GoalService;
use App\Support\Money;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Goal */
class GoalResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        $stats = app(GoalService::class)->stats($this->resource);
        $money = fn (?int $minor) => $minor === null ? null : Money::toDecimal($minor, $this->currency);

        return [
            'id' => $this->id,
            'name' => $this->name,
            'kind' => $this->kind,
            'currency' => $this->currency,
            'target_amount' => $money($this->target_amount),
            'target_amount_minor' => $this->target_amount,
            'current_amount' => $money($this->current_amount),
            'current_amount_minor' => $this->current_amount,
            'target_date' => $this->target_date?->toDateString(),
            'account_id' => $this->account_id,
            'icon' => $this->icon,
            'color' => $this->color,
            'notes' => $this->notes,
            'achieved' => $this->achieved_at !== null,
            'achieved_at' => $this->achieved_at?->toIso8601String(),
            'archived' => $this->archived_at !== null,
            'progress' => [
                'percent' => $stats['percent'],
                'remaining' => $money($stats['remaining']),
                'remaining_minor' => $stats['remaining'],
                'monthly_needed' => $money($stats['monthly_needed']),
                'monthly_needed_minor' => $stats['monthly_needed'],
                'average_monthly_contribution_minor' => $stats['average_monthly_contribution'],
                'expected_completion_date' => $stats['expected_completion_date'],
            ],
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
