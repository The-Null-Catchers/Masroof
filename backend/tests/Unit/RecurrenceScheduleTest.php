<?php

namespace Tests\Unit;

use App\Models\RecurringTransaction;
use App\Services\RecurrenceSchedule;
use Carbon\CarbonImmutable;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

class RecurrenceScheduleTest extends TestCase
{
    private function rule(string $frequency, string $start, int $interval = 1, ?string $end = null, ?string $next = null): RecurringTransaction
    {
        $rule = new RecurringTransaction;
        $rule->forceFill(['frequency' => $frequency, 'interval' => $interval, 'starts_on' => $start, 'ends_on' => $end]);
        $rule->next_occurrence_on = $next;

        return $rule;
    }

    /** @return array<string, array{string, string, int, array<int, string>}> */
    public static function sequences(): array
    {
        return [
            'monthly from the 31st keeps its anchor day' => ['monthly', '2026-01-31', 1, ['2026-01-31', '2026-02-28', '2026-03-31', '2026-04-30']],
            'every two weeks' => ['weekly', '2026-09-01', 2, ['2026-09-01', '2026-09-15', '2026-09-29']],
            'yearly on Feb 29' => ['yearly', '2028-02-29', 1, ['2028-02-29', '2029-02-28', '2030-02-28', '2032-02-29']],
            'every 10 days' => ['daily', '2026-09-25', 10, ['2026-09-25', '2026-10-05', '2026-10-15']],
        ];
    }

    /** @param array<int, string> $expected */
    #[DataProvider('sequences')]
    public function test_occurrences(string $frequency, string $start, int $interval, array $expected): void
    {
        $schedule = new RecurrenceSchedule;
        $rule = $this->rule($frequency, $start, $interval);
        $n = $frequency === 'yearly' ? [0, 1, 2, 4] : array_keys($expected);

        foreach ($expected as $i => $date) {
            $this->assertSame($date, $schedule->occurrence($rule, $n[$i])->toDateString());
        }
    }

    public function test_next_on_or_after_and_end_date(): void
    {
        $schedule = new RecurrenceSchedule;
        $rule = $this->rule('monthly', '2026-01-31', end: '2026-05-15');

        $this->assertSame('2026-01-31', $schedule->nextOnOrAfter($rule, CarbonImmutable::parse('2025-12-01'))?->toDateString());
        $this->assertSame('2026-03-31', $schedule->nextOnOrAfter($rule, CarbonImmutable::parse('2026-03-01'))?->toDateString());
        $this->assertSame('2026-04-30', $schedule->nextOnOrAfter($rule, CarbonImmutable::parse('2026-04-30'))?->toDateString());
        $this->assertNull($schedule->nextOnOrAfter($rule, CarbonImmutable::parse('2026-05-01')));
    }

    public function test_due_through_catches_up_missed_dates(): void
    {
        $schedule = new RecurrenceSchedule;
        $rule = $this->rule('weekly', '2026-08-01', next: '2026-08-15');

        $this->assertSame(
            ['2026-08-15', '2026-08-22', '2026-08-29', '2026-09-05'],
            array_map(fn ($d) => $d->toDateString(), $schedule->dueThrough($rule, CarbonImmutable::parse('2026-09-10'))),
        );
    }
}
