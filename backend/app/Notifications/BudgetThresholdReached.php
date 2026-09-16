<?php

namespace App\Notifications;

class BudgetThresholdReached extends MasroofNotification
{
    public function __construct(
        public readonly string $budgetId,
        public readonly string $budgetName,
        public readonly int $threshold,
        public readonly string $spent,
        public readonly string $amount,
    ) {}

    public function type(): string
    {
        return 'budget_threshold';
    }

    public function params(): array
    {
        return ['budget' => $this->budgetName, 'threshold' => $this->threshold, 'spent' => $this->spent, 'amount' => $this->amount];
    }

    public function action(): ?string
    {
        return '/budgets';
    }
}
