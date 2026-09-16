<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\V1\GoalResource;
use App\Http\Resources\V1\RecurringTransactionResource;
use App\Http\Resources\V1\TransactionResource;
use App\Models\Budget;
use App\Services\AnalyticsService;
use App\Services\BudgetCalculator;
use App\Services\Insights\Insight;
use App\Services\Insights\InsightEngine;
use App\Support\Money;
use App\Support\Period;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Everything the home screen needs in one request. Amounts are minor units in
 * the user's default currency unless a row carries its own currency.
 */
class DashboardController extends Controller
{
    public function __invoke(
        Request $request,
        AnalyticsService $analytics,
        BudgetCalculator $budgets,
        InsightEngine $insights,
    ): JsonResponse {
        $user = $request->user();
        $currency = $user->currency;
        $month = Period::financialMonth($user);
        $totals = $analytics->totals($user, $currency, $month);

        $netWorth = $user->accounts()->toBase()
            ->whereNull('archived_at')->where('include_in_total', true)
            ->groupBy('currency')->selectRaw('currency, SUM(balance) AS total')->get()
            ->map(fn ($row) => ['currency' => $row->currency, 'total_minor' => (int) $row->total, 'total' => Money::toDecimal((int) $row->total, $row->currency)])
            ->values();

        $activeBudgets = $user->budgets()->whereNull('archived_at')->where('currency', $currency)->with('categories')->get();
        $budgetRows = $activeBudgets->map(fn (Budget $b) => ['budget' => $b, 'progress' => $budgets->progress($b, $user)]);
        // Prefer overall (uncategorized) monthly budgets for "remaining budget"; fall back to all monthly budgets.
        $monthly = $budgetRows->filter(fn ($row) => $row['budget']->period === 'monthly');
        $overall = $monthly->filter(fn ($row) => $row['budget']->categories->isEmpty());
        $remainingSource = $overall->isNotEmpty() ? $overall : $monthly;

        $spending = $analytics->expensesByCategory($user, $currency, $month)->values()->take(6);

        return response()->json(['data' => [
            'currency' => $currency,
            'period' => $month->toArray($user->timezone),
            'net_worth' => $netWorth,
            'month' => [
                'income_minor' => $totals['income'],
                'expense_minor' => $totals['expense'],
                'savings_minor' => $totals['income'] - $totals['expense'],
                'savings_rate' => $totals['income'] > 0 ? round(($totals['income'] - $totals['expense']) * 100 / $totals['income'], 1) : null,
            ],
            'budget' => $remainingSource->isEmpty() ? null : [
                'amount_minor' => $remainingSource->sum(fn ($row) => $row['budget']->amount),
                'spent_minor' => $remainingSource->sum(fn ($row) => $row['progress']['spent']),
                'remaining_minor' => $remainingSource->sum(fn ($row) => $row['progress']['remaining']),
            ],
            'budgets' => $budgetRows->sortByDesc(fn ($row) => $row['progress']['percent'])->take(4)->map(fn ($row) => [
                'id' => $row['budget']->id,
                'name' => $row['budget']->name,
                'amount_minor' => $row['budget']->amount,
                'spent_minor' => $row['progress']['spent'],
                'percent' => $row['progress']['percent'],
                'status' => $row['progress']['status'],
            ])->values(),
            'spending_by_category' => $spending,
            'monthly_trend' => $analytics->monthlyTrend($user, $currency, 6),
            'goals' => GoalResource::collection(
                $user->goals()->whereNull('archived_at')->whereNull('achieved_at')->orderBy('target_date')->limit(3)->get(),
            ),
            'recent_transactions' => TransactionResource::collection(
                $user->transactions()->with(['account', 'transferAccount', 'category', 'tags'])->latest('occurred_at')->limit(6)->get(),
            ),
            'upcoming_recurring' => RecurringTransactionResource::collection(
                $user->recurringTransactions()->with('category')->whereNull('paused_at')->whereNotNull('next_occurrence_on')
                    ->where('next_occurrence_on', '<=', now($user->timezone)->addDays(14)->toDateString())
                    ->orderBy('next_occurrence_on')->limit(5)->get(),
            ),
            'insights' => array_map(fn (Insight $i) => $i->toArray(), array_slice($insights->generate($user), 0, 3)),
        ]]);
    }
}
