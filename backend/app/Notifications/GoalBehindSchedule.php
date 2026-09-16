<?php

namespace App\Notifications;

class GoalBehindSchedule extends MasroofNotification
{
    public function __construct(
        public readonly string $goalId,
        public readonly string $goalName,
        public readonly string $monthlyNeeded,
        public readonly int $percent,
    ) {}

    public function type(): string
    {
        return 'goal_reminder';
    }

    public function params(): array
    {
        return ['goal' => $this->goalName, 'monthly' => $this->monthlyNeeded, 'percent' => $this->percent];
    }

    public function action(): ?string
    {
        return '/goals';
    }
}
