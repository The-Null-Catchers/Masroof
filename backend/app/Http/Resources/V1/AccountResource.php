<?php

namespace App\Http\Resources\V1;

use App\Models\Account;
use App\Support\Money;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Account */
class AccountResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'type' => $this->type->value,
            'currency' => $this->currency,
            'opening_balance' => Money::toDecimal($this->opening_balance, $this->currency),
            'opening_balance_minor' => $this->opening_balance,
            'balance' => Money::toDecimal($this->balance, $this->currency),
            'balance_minor' => $this->balance,
            'color' => $this->color,
            'icon' => $this->icon,
            'notes' => $this->notes,
            'include_in_total' => $this->include_in_total,
            'archived' => $this->archived_at !== null,
            'archived_at' => $this->archived_at?->toIso8601String(),
            'sort_order' => $this->sort_order,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
