<?php

namespace App\Support;

use App\Models\User;
use Carbon\CarbonImmutable;

/**
 * A half-open time window [start, end) expressed in UTC, computed from the
 * user's timezone, financial month start day and week start.
 */
final readonly class Period
{
    public function __construct(
        public CarbonImmutable $start,
        public CarbonImmutable $end,
    ) {}

    /** Financial month containing $at (e.g. 25th → 24th when the month starts on the 25th). */
    public static function financialMonth(User $user, ?CarbonImmutable $at = null, int $offset = 0): self
    {
        $tz = $user->timezone;
        $day = $user->settingsOrDefault()->month_start_day;
        $local = ($at ?? CarbonImmutable::now())->setTimezone($tz);

        $start = $local->startOfMonth()->setDay($day)->startOfDay();
        if ($local->lt($start)) {
            $start = $start->subMonthNoOverflow();
        }
        $start = $start->addMonthsNoOverflow($offset);

        return new self($start->utc(), $start->addMonthNoOverflow()->utc());
    }

    public static function week(User $user, ?CarbonImmutable $at = null): self
    {
        $local = ($at ?? CarbonImmutable::now())->setTimezone($user->timezone);
        $start = $local->startOfWeek($user->week_start)->startOfDay();

        return new self($start->utc(), $start->addWeek()->utc());
    }

    /** Inclusive local dates, e.g. a custom budget from 2026-09-01 to 2026-09-15. */
    public static function dates(User $user, string $from, string $to): self
    {
        $start = CarbonImmutable::parse($from, $user->timezone)->startOfDay();
        $end = CarbonImmutable::parse($to, $user->timezone)->startOfDay()->addDay();

        return new self($start->utc(), $end->utc());
    }

    public function contains(CarbonImmutable $moment): bool
    {
        return $moment->gte($this->start) && $moment->lt($this->end);
    }

    /** Whole local days remaining from $now until the end, counting today (min 0). */
    public function daysLeft(string $timezone, ?CarbonImmutable $now = null): int
    {
        $now = ($now ?? CarbonImmutable::now());
        if ($now->gte($this->end)) {
            return 0;
        }
        $from = $now->lt($this->start) ? $this->start : $now;
        $today = $from->setTimezone($timezone)->startOfDay();
        $last = $this->end->setTimezone($timezone)->subSecond()->startOfDay();

        return (int) $today->diffInDays($last) + 1;
    }

    public function days(string $timezone): int
    {
        return (int) $this->start->setTimezone($timezone)->startOfDay()
            ->diffInDays($this->end->setTimezone($timezone)->startOfDay());
    }

    public function previous(): self
    {
        $length = $this->start->diffInSeconds($this->end);

        return new self($this->start->subSeconds((int) $length), $this->start);
    }

    /** @return array{start: string, end: string} */
    public function toArray(string $timezone): array
    {
        return [
            'start' => $this->start->setTimezone($timezone)->toDateString(),
            // Inclusive last day for display.
            'end' => $this->end->setTimezone($timezone)->subSecond()->toDateString(),
        ];
    }
}
