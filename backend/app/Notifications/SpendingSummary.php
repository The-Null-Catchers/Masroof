<?php

namespace App\Notifications;

class SpendingSummary extends MasroofNotification
{
    /** @param 'weekly'|'monthly' $period */
    public function __construct(
        public readonly string $period,
        public readonly string $income,
        public readonly string $expense,
        public readonly int $savingsRate,
        public readonly string $topCategory,
    ) {}

    public function type(): string
    {
        return "{$this->period}_summary";
    }

    public function params(): array
    {
        return ['income' => $this->income, 'expense' => $this->expense, 'rate' => $this->savingsRate, 'category' => $this->topCategory];
    }

    public function action(): ?string
    {
        return '/analytics';
    }
}
