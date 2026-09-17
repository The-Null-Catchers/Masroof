<?php

namespace App\Reports;

use App\Models\Budget;
use App\Models\Goal;
use App\Models\Transaction;
use App\Models\User;
use App\Services\AnalyticsService;
use App\Services\BudgetCalculator;
use App\Services\GoalService;
use App\Support\Money;
use App\Support\Period;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\App;

/** Builds the report datasets. All money values are exact (minor units → display). */
class ReportBuilder
{
    public const TYPES = ['transactions', 'monthly', 'budgets', 'income_expense', 'categories'];

    public function __construct(
        private readonly AnalyticsService $analytics,
        private readonly BudgetCalculator $budgets,
        private readonly GoalService $goals,
    ) {}

    /** @param array<string, mixed> $params */
    public function build(User $user, string $type, array $params): Report
    {
        $locale = $params['locale'] ?? $user->locale;
        $previous = App::getLocale();
        App::setLocale($locale);

        try {
            return match ($type) {
                'transactions' => $this->transactions($user, $params, $locale),
                'budgets' => $this->budgetReport($user, $locale),
                'income_expense' => $this->incomeExpense($user, (int) ($params['months'] ?? 12), $locale),
                'categories' => $this->categories($user, $params, $locale),
                default => $this->monthly($user, (int) ($params['offset'] ?? 0), $locale),
            };
        } finally {
            App::setLocale($previous);
        }
    }

    /** @param array<string, mixed> $params */
    private function period(User $user, array $params): Period
    {
        return isset($params['from'], $params['to'])
            ? Period::dates($user, $params['from'], $params['to'])
            : Period::financialMonth($user, null, (int) ($params['offset'] ?? 0));
    }

    private function money(int $minor, string $currency, string $locale): string
    {
        return Money::display($minor, $currency, $locale);
    }

    private function range(Period $period, User $user): string
    {
        $dates = $period->toArray($user->timezone);

        return "{$dates['start']} → {$dates['end']}";
    }

    private function categoryName(?string $name, ?string $key): string
    {
        return $key && trans()->has("masroof_categories.{$key}") ? __("masroof_categories.{$key}") : ($name ?? __('reports.uncategorized'));
    }

    /** @param array<string, mixed> $params */
    private function transactions(User $user, array $params, string $locale): Report
    {
        $period = $this->period($user, $params);
        $report = new Report(__('reports.transactions.title'), $this->range($period, $user), $locale, 'transactions');

        $query = $user->transactions()
            ->with(['account', 'transferAccount', 'category', 'tags'])
            ->where('occurred_at', '>=', $period->start)
            ->where('occurred_at', '<', $period->end)
            ->when($params['account_id'] ?? null, fn ($q, $id) => $q->where(fn ($q) => $q->where('account_id', $id)->orWhere('transfer_account_id', $id)))
            ->when($params['category_id'] ?? null, fn ($q, $id) => $q->where('category_id', $id))
            ->when($params['transaction_type'] ?? null, fn ($q, $t) => $q->where('type', $t))
            ->orderBy('occurred_at');

        $totals = $this->analytics->totals($user, $user->currency, $period);
        $report->metric(__('reports.income'), $this->money($totals['income'], $user->currency, $locale), 'income')
            ->metric(__('reports.expenses'), $this->money($totals['expense'], $user->currency, $locale), 'expense')
            ->metric(__('reports.count'), (string) (clone $query)->count());

        $table = new ReportTable(
            __('reports.transactions.title'),
            [__('reports.columns.date'), __('reports.columns.type'), __('reports.columns.description'), __('reports.columns.category'), __('reports.columns.account'), __('reports.columns.amount'), __('reports.columns.currency'), __('reports.columns.tags'), __('reports.columns.note')],
            [5 => true],
            __('reports.empty'),
        );

        $query->lazy(500)->each(function (Transaction $t) use ($table, $user) {
            $signed = match ($t->type->value) {
                'expense', 'transfer' => -$t->amount,
                default => $t->amount,
            };
            $table->row([
                $t->occurred_at->setTimezone($user->timezone)->format('Y-m-d H:i'),
                __("reports.types.{$t->type->value}"),
                $t->type->value === 'transfer' ? __('reports.transfer_to', ['account' => $t->transferAccount->name ?? '—']) : ($t->merchant ?? ''),
                $t->category ? $this->categoryName($t->category->name, $t->category->default_key) : '',
                $t->account->name ?? '',
                Money::toDecimal($signed, $t->currency),
                $t->currency,
                $t->tags->pluck('name')->implode(', '),
                $t->note ?? '',
            ]);
        });

        return $report->table($table);
    }

    private function monthly(User $user, int $offset, string $locale): Report
    {
        $period = Period::financialMonth($user, null, $offset);
        $currency = $user->currency;
        $summary = $this->analytics->summary($user, $currency, $period, Period::financialMonth($user, null, $offset - 1));
        $report = new Report(__('reports.monthly.title'), $this->range($period, $user), $locale, 'monthly-report');

        $report->metric(__('reports.income'), $this->money($summary['income'], $currency, $locale), 'income')
            ->metric(__('reports.expenses'), $this->money($summary['expense'], $currency, $locale), 'expense')
            ->metric(__('reports.savings'), $this->money($summary['savings'], $currency, $locale), $summary['savings'] >= 0 ? 'income' : 'expense')
            ->metric(__('reports.savings_rate'), $summary['savings_rate'] === null ? '—' : round($summary['savings_rate']).'%')
            ->metric(__('reports.avg_daily'), $this->money($summary['average_daily_spending'], $currency, $locale));

        $categories = new ReportTable(__('reports.monthly.categories'), [__('reports.columns.category'), __('reports.columns.amount'), __('reports.columns.share'), __('reports.columns.change')], [1 => true, 2 => true, 3 => true], __('reports.empty'));
        foreach ($summary['categories'] as $row) {
            $categories->row([
                $this->categoryName($row['name'], $row['default_key']),
                $this->money($row['total'], $currency, $locale),
                $row['share'].'%',
                $row['change'] === null ? '—' : ($row['change'] > 0 ? '+' : '').$row['change'].'%',
            ]);
        }
        $report->table($categories);
        // Past months show budgets as of their last day; the current month as of now.
        $report->table($this->budgetTable($user, $locale, $period->end->subSecond()->min(CarbonImmutable::now())));

        $goals = new ReportTable(__('reports.monthly.goals'), [__('reports.columns.goal'), __('reports.columns.saved'), __('reports.columns.target'), __('reports.columns.progress')], [1 => true, 2 => true, 3 => true], __('reports.empty'));
        $user->goals()->whereNull('archived_at')->orderBy('created_at')->get()->each(function (Goal $goal) use ($goals, $locale) {
            $stats = $this->goals->stats($goal);
            $goals->row([$goal->name, $this->money($goal->current_amount, $goal->currency, $locale), $this->money($goal->target_amount, $goal->currency, $locale), round($stats['percent']).'%']);
        });
        $report->table($goals);

        $largest = new ReportTable(__('reports.monthly.largest'), [__('reports.columns.date'), __('reports.columns.description'), __('reports.columns.amount')], [2 => true], __('reports.empty'));
        foreach ($summary['largest_expenses'] as $row) {
            $largest->row([
                CarbonImmutable::parse($row['occurred_at'])->setTimezone($user->timezone)->toDateString(),
                $row['merchant'] ?? $this->categoryName($row['category'], $row['default_key']),
                $this->money($row['amount'], $currency, $locale),
            ]);
        }
        $report->table($largest);

        $merchants = new ReportTable(__('reports.monthly.merchants'), [__('reports.columns.merchant'), __('reports.columns.count'), __('reports.columns.amount')], [1 => true, 2 => true], __('reports.empty'));
        foreach ($summary['top_merchants'] as $row) {
            $merchants->row([$row['merchant'], $row['count'], $this->money($row['total'], $currency, $locale)]);
        }

        return $report->table($merchants);
    }

    private function budgetReport(User $user, string $locale): Report
    {
        $report = new Report(__('reports.budgets.title'), now($user->timezone)->toDateString(), $locale, 'budgets');

        return $report->table($this->budgetTable($user, $locale));
    }

    private function budgetTable(User $user, string $locale, ?CarbonImmutable $at = null): ReportTable
    {
        $table = new ReportTable(
            __('reports.budgets.title'),
            [__('reports.columns.budget'), __('reports.columns.period'), __('reports.columns.budgeted'), __('reports.columns.spent'), __('reports.columns.remaining'), __('reports.columns.progress'), __('reports.columns.status')],
            [2 => true, 3 => true, 4 => true, 5 => true],
            __('reports.empty'),
        );
        $user->budgets()->whereNull('archived_at')->with('categories')->orderBy('created_at')->get()->each(function (Budget $budget) use ($table, $user, $locale, $at) {
            $p = $this->budgets->progress($budget, $user, $at);
            $table->row([
                $budget->name,
                "{$p['period']['start']} → {$p['period']['end']}",
                $this->money($budget->amount, $budget->currency, $locale),
                $this->money($p['spent'], $budget->currency, $locale),
                $this->money($p['remaining'], $budget->currency, $locale),
                round($p['percent']).'%',
                __("reports.status.{$p['status']}"),
            ]);
        });

        return $table;
    }

    private function incomeExpense(User $user, int $months, string $locale): Report
    {
        $currency = $user->currency;
        $trend = $this->analytics->monthlyTrend($user, $currency, max(2, min(24, $months)));
        $report = new Report(__('reports.income_expense.title'), "{$trend[0]['label']} → ".end($trend)['label'], $locale, 'income-expense');

        $table = new ReportTable(__('reports.income_expense.title'), [__('reports.columns.month'), __('reports.income'), __('reports.expenses'), __('reports.savings'), __('reports.savings_rate'), __('reports.columns.closing_balance')], [1 => true, 2 => true, 3 => true, 4 => true, 5 => true]);
        $income = $expense = 0;
        foreach ($trend as $month) {
            $income += $month['income'];
            $expense += $month['expense'];
            $table->row([
                $month['label'],
                $this->money($month['income'], $currency, $locale),
                $this->money($month['expense'], $currency, $locale),
                $this->money($month['savings'], $currency, $locale),
                $month['savings_rate'] === null ? '—' : round($month['savings_rate']).'%',
                $this->money($month['closing_balance'], $currency, $locale),
            ]);
        }

        return $report
            ->metric(__('reports.income'), $this->money($income, $currency, $locale), 'income')
            ->metric(__('reports.expenses'), $this->money($expense, $currency, $locale), 'expense')
            ->metric(__('reports.savings'), $this->money($income - $expense, $currency, $locale))
            ->table($table);
    }

    /** @param array<string, mixed> $params */
    private function categories(User $user, array $params, string $locale): Report
    {
        $period = $this->period($user, $params);
        $currency = $user->currency;
        $rows = $this->analytics->expensesByCategory($user, $currency, $period);
        $total = $rows->sum('total');
        $report = new Report(__('reports.categories.title'), $this->range($period, $user), $locale, 'category-spending');
        $report->metric(__('reports.expenses'), $this->money((int) $total, $currency, $locale), 'expense');

        $table = new ReportTable(__('reports.categories.title'), [__('reports.columns.category'), __('reports.columns.amount'), __('reports.columns.count'), __('reports.columns.share')], [1 => true, 2 => true, 3 => true], __('reports.empty'));
        foreach ($rows as $row) {
            $table->row([
                $this->categoryName($row['name'], $row['default_key']),
                $this->money($row['total'], $currency, $locale),
                $row['count'],
                $total > 0 ? round($row['total'] * 100 / $total, 1).'%' : '0%',
            ]);
        }

        return $report->table($table);
    }
}
