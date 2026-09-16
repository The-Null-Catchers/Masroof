<?php

namespace App\Http\Resources\V1;

use App\Models\Transaction;
use App\Support\Money;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/** @mixin Transaction */
class TransactionResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        $transferCurrency = $this->transfer_account_id
            ? ($this->relationLoaded('transferAccount') ? $this->transferAccount?->currency : $this->transferAccount()->value('currency'))
            : null;

        return [
            'id' => $this->id,
            'type' => $this->type->value,
            'amount' => Money::toDecimal($this->amount, $this->currency),
            'amount_minor' => $this->amount,
            'currency' => $this->currency,
            'account_id' => $this->account_id,
            'category_id' => $this->category_id,
            'transfer_account_id' => $this->transfer_account_id,
            'transfer_amount' => $this->transfer_amount !== null && $transferCurrency
                ? Money::toDecimal($this->transfer_amount, $transferCurrency)
                : null,
            'transfer_amount_minor' => $this->transfer_amount,
            'transfer_currency' => $transferCurrency,
            'occurred_at' => $this->occurred_at->toIso8601String(),
            'payee' => $this->payee,
            'note' => $this->note,
            'account' => $this->whenLoaded('account', fn () => [
                'id' => $this->account->id,
                'name' => $this->account->name,
                'type' => $this->account->type->value,
                'color' => $this->account->color,
            ]),
            'transfer_account' => $this->whenLoaded('transferAccount', fn () => $this->transferAccount ? [
                'id' => $this->transferAccount->id,
                'name' => $this->transferAccount->name,
                'type' => $this->transferAccount->type->value,
                'color' => $this->transferAccount->color,
            ] : null),
            'category' => $this->whenLoaded('category', fn () => $this->category ? [
                'id' => $this->category->id,
                'name' => $this->category->name,
                'default_key' => $this->category->default_key,
                'icon' => $this->category->icon,
                'color' => $this->category->color,
            ] : null),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
