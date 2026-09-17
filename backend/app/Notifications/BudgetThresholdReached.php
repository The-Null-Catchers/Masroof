<?php

namespace App\Notifications;

class BudgetThresholdReached extends MasroofNotification
{
    public function __construct(
        public readonly string $budgetId,
        public readonly string $budgetName,
        public readonly int $threshold,
        public readonly int $spent,
        public readonly int $amount,
        public readonly string $currency,
    ) {}

    public function type(): string
    {
        return 'budget_threshold';
    }

    public function params(): array
    {
        return [
            'budget' => $this->budgetName,
            'threshold' => $this->threshold,
            'spent' => ['minor' => $this->spent, 'currency' => $this->currency],
            'amount' => ['minor' => $this->amount, 'currency' => $this->currency],
        ];
    }

    public function action(): ?string
    {
        return '/budgets';
    }
}
