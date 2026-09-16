<?php

namespace Tests\Unit;

use App\Models\User;
use App\Support\Period;
use Carbon\CarbonImmutable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PeriodTest extends TestCase
{
    use RefreshDatabase;

    private function user(int $startDay = 1, string $tz = 'Asia/Hebron', int $weekStart = 6): User
    {
        $user = User::factory()->create(['timezone' => $tz, 'week_start' => $weekStart]);
        $user->settingsOrDefault()->forceFill(['month_start_day' => $startDay])->save();

        return $user->refresh();
    }

    public function test_calendar_month_in_user_timezone(): void
    {
        $period = Period::financialMonth($this->user(), CarbonImmutable::parse('2026-09-16 12:00', 'UTC'));

        $this->assertSame(['start' => '2026-09-01', 'end' => '2026-09-30'], $period->toArray('Asia/Hebron'));
        // Midnight in Hebron (UTC+3 in September) is 21:00 UTC the previous day.
        $this->assertSame('2026-08-31 21:00:00', $period->start->toDateTimeString());
    }

    public function test_financial_month_starting_on_the_25th(): void
    {
        $user = $this->user(25);

        $this->assertSame(['start' => '2026-08-25', 'end' => '2026-09-24'], Period::financialMonth($user, CarbonImmutable::parse('2026-09-16', 'UTC'))->toArray('Asia/Hebron'));
        $this->assertSame(['start' => '2026-09-25', 'end' => '2026-10-24'], Period::financialMonth($user, CarbonImmutable::parse('2026-09-26', 'UTC'))->toArray('Asia/Hebron'));
        $this->assertSame(['start' => '2026-07-25', 'end' => '2026-08-24'], Period::financialMonth($user, CarbonImmutable::parse('2026-09-16', 'UTC'), -1)->toArray('Asia/Hebron'));
    }

    public function test_week_respects_week_start(): void
    {
        // 2026-09-16 is a Wednesday; week starts Saturday.
        $this->assertSame(['start' => '2026-09-12', 'end' => '2026-09-18'], Period::week($this->user(), CarbonImmutable::parse('2026-09-16 10:00', 'UTC'))->toArray('Asia/Hebron'));
    }

    public function test_days_left_counts_today(): void
    {
        $user = $this->user();
        $period = Period::financialMonth($user, CarbonImmutable::parse('2026-09-16 10:00', 'UTC'));

        $this->assertSame(15, $period->daysLeft('Asia/Hebron', CarbonImmutable::parse('2026-09-16 10:00', 'UTC')));
        $this->assertSame(1, $period->daysLeft('Asia/Hebron', CarbonImmutable::parse('2026-09-30 10:00', 'UTC')));
        $this->assertSame(0, $period->daysLeft('Asia/Hebron', CarbonImmutable::parse('2026-10-01 10:00', 'UTC')));
        $this->assertSame(30, $period->days('Asia/Hebron'));
    }
}
