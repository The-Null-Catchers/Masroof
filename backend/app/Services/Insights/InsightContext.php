<?php

namespace App\Services\Insights;

use App\Models\User;
use App\Support\Money;
use App\Support\Period;
use Carbon\CarbonImmutable;

/** Shared inputs for insight rules: who, which currency, and "now". */
final readonly class InsightContext
{
    public Period $month;

    public function __construct(
        public User $user,
        public string $currency,
        public CarbonImmutable $now,
    ) {
        $this->month = Period::financialMonth($user, $now);
    }

    public function money(int $minor): string
    {
        return Money::display($minor, $this->currency);
    }

    /** Minimum amount worth mentioning (e.g. 20.00 in the user's currency). */
    public function noticeable(int $majorUnits = 20): int
    {
        return $majorUnits * (10 ** Money::exponent($this->currency));
    }
}
