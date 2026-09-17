<?php

namespace App\Notifications;

class SpendingSummary extends MasroofNotification
{
    /** @param 'weekly'|'monthly' $period */
    public function __construct(
        public readonly string $period,
        public readonly int $income,
        public readonly int $expense,
        public readonly string $currency,
        public readonly int $savingsRate,
        public readonly string $topCategory,
    ) {}

    public function type(): string
    {
        return "{$this->period}_summary";
    }

    public function params(): array
    {
        return [
            'income' => ['minor' => $this->income, 'currency' => $this->currency],
            'expense' => ['minor' => $this->expense, 'currency' => $this->currency],
            'rate' => $this->savingsRate,
            'category' => $this->topCategory,
        ];
    }

    public function action(): ?string
    {
        return '/analytics';
    }
}
