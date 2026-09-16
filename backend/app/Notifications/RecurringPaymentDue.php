<?php

namespace App\Notifications;

class RecurringPaymentDue extends MasroofNotification
{
    public function __construct(
        public readonly string $ruleId,
        public readonly string $name,
        public readonly string $amount,
        public readonly string $date,
        public readonly bool $isBill,
    ) {}

    public function type(): string
    {
        return $this->isBill ? 'bill_reminder' : 'recurring_reminder';
    }

    public function params(): array
    {
        return ['name' => $this->name, 'amount' => $this->amount, 'date' => $this->date];
    }

    public function action(): ?string
    {
        return '/recurring';
    }
}
