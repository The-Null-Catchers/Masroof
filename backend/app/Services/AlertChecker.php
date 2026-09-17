<?php

namespace App\Services;

use App\Models\User;
use App\Notifications\BudgetThresholdReached;
use App\Notifications\GoalBehindSchedule;
use App\Notifications\SpendingSummary;
use App\Support\Period;
use Carbon\CarbonImmutable;

/** Evaluates budget, goal and summary notifications for one user. */
class AlertChecker
{
    public function __construct(
        private readonly BudgetCalculator $budgets,
        private readonly GoalService $goals,
        private readonly AnalyticsService $analytics,
        private readonly NotificationService $notifications,
    ) {}

    /**
     * Notifies once per budget, period and threshold. When several thresholds
     * are crossed at once only the highest is sent.
     */
    public function budgets(User $user, ?CarbonImmutable $now = null): int
    {
        $sent = 0;
        foreach ($user->budgets()->whereNull('archived_at')->with('categories')->get() as $budget) {
            $progress = $this->budgets->progress($budget, $user, $now);
            $reached = $progress['reached_thresholds'];
            if ($reached === [] || $progress['days_left'] === 0) {
                continue;
            }
            $prefix = "budget:{$budget->id}:{$progress['period']['start']}:";
            $highest = max($reached);
            foreach ($reached as $threshold) {
                if ($threshold !== $highest) {
                    $this->notifications->markDelivered($user, $prefix.$threshold);
                }
            }
            $sent += (int) $this->notifications->sendOnce($user, new BudgetThresholdReached(
                $budget->id,
                $budget->name,
                $highest,
                $progress['spent'],
                $budget->amount,
                $budget->currency,
            ), $prefix.$highest);
        }

        return $sent;
    }

    /** Monthly nudge for goals whose saving pace is below what the deadline needs. */
    public function goals(User $user, ?CarbonImmutable $now = null): int
    {
        $now ??= CarbonImmutable::now();
        $month = $now->setTimezone($user->timezone)->format('Y-m');
        $sent = 0;

        foreach ($user->goals()->whereNull('archived_at')->whereNull('achieved_at')->whereNotNull('target_date')->get() as $goal) {
            $stats = $this->goals->stats($goal, $now);
            if ($stats['monthly_needed'] === null || $stats['average_monthly_contribution'] >= $stats['monthly_needed']) {
                continue;
            }
            $sent += (int) $this->notifications->sendOnce($user, new GoalBehindSchedule(
                $goal->id,
                $goal->name,
                $stats['monthly_needed'],
                $goal->currency,
                (int) floor($stats['percent']),
            ), "goal:{$goal->id}:{$month}");
        }

        return $sent;
    }

    /** Weekly summary on the first day of the week, monthly on the financial month start. */
    public function summaries(User $user, ?CarbonImmutable $now = null): int
    {
        $now ??= CarbonImmutable::now();
        $local = $now->setTimezone($user->timezone);
        $sent = 0;

        if ($local->dayOfWeek === $user->week_start) {
            $week = Period::week($user, $now);
            $sent += (int) $this->summary($user, 'weekly', new Period($week->start->subWeek(), $week->start), "weekly:{$local->toDateString()}");
        }

        if ($local->day === $user->settingsOrDefault()->month_start_day) {
            $sent += (int) $this->summary($user, 'monthly', Period::financialMonth($user, $now, -1), "monthly:{$local->format('Y-m')}");
        }

        return $sent;
    }

    private function summary(User $user, string $kind, Period $period, string $key): bool
    {
        $totals = $this->analytics->totals($user, $user->currency, $period);
        if ($totals['income'] === 0 && $totals['expense'] === 0) {
            return false;
        }
        $top = $this->analytics->expensesByCategory($user, $user->currency, $period)->first();
        $category = $top === null ? '—' : ($top['default_key'] && trans()->has("masroof_categories.{$top['default_key']}", $user->locale)
            ? __("masroof_categories.{$top['default_key']}", [], $user->locale)
            : ($top['name'] ?? '—'));

        return $this->notifications->sendOnce($user, new SpendingSummary(
            $kind,
            $totals['income'],
            $totals['expense'],
            $user->currency,
            $totals['income'] > 0 ? (int) round(($totals['income'] - $totals['expense']) * 100 / $totals['income']) : 0,
            $category,
        ), $key);
    }
}
