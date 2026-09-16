<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Support\Money;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class ReportController extends Controller
{
    /**
     * Income/expense totals, category breakdown and a time series for a period.
     * Amounts are grouped per currency; they are never summed across currencies.
     */
    public function summary(Request $request): JsonResponse
    {
        $user = $request->user();
        $validated = $request->validate([
            'from' => ['required', 'date'],
            'to' => ['required', 'date', 'after_or_equal:from'],
            'account_id' => ['sometimes', 'ulid'],
            'interval' => ['sometimes', Rule::in(['day', 'month'])],
        ]);

        $tz = $user->timezone;
        $from = Carbon::parse($validated['from'], $tz)->startOfDay()->utc();
        $to = Carbon::parse($validated['to'], $tz)->endOfDay()->utc();
        if ($from->diffInDays($to) > 3660) {
            abort(422, __('masroof.range_too_large'));
        }
        $interval = $validated['interval'] ?? ($from->diffInDays($to) > 62 ? 'month' : 'day');

        $base = DB::table('transactions')
            ->where('transactions.user_id', $user->id)
            ->whereNull('transactions.deleted_at')
            ->whereIn('transactions.type', ['income', 'expense'])
            ->whereBetween('transactions.occurred_at', [$from, $to])
            ->when($validated['account_id'] ?? null, fn ($q, $id) => $q->where('transactions.account_id', $id));

        $totals = (clone $base)
            ->selectRaw('currency, type, SUM(amount) AS total, COUNT(*) AS count')
            ->groupBy('currency', 'type')
            ->get();

        $currencies = [];
        foreach ($totals as $row) {
            $c = $row->currency;
            $currencies[$c] ??= ['currency' => $c, 'income_minor' => 0, 'expense_minor' => 0, 'count' => 0];
            $currencies[$c][$row->type.'_minor'] = (int) $row->total;
            $currencies[$c]['count'] += (int) $row->count;
        }
        $currencies = array_values(array_map(function (array $row) {
            $net = $row['income_minor'] - $row['expense_minor'];

            return $row + [
                'income' => Money::toDecimal($row['income_minor'], $row['currency']),
                'expense' => Money::toDecimal($row['expense_minor'], $row['currency']),
                'net' => Money::toDecimal($net, $row['currency']),
                'net_minor' => $net,
            ];
        }, $currencies));

        // Roll subcategories up into their parent for the breakdown.
        $byCategory = (clone $base)
            ->leftJoin('categories as c', 'c.id', '=', 'transactions.category_id')
            ->leftJoin('categories as p', 'p.id', '=', 'c.parent_id')
            ->selectRaw('transactions.currency, transactions.type,
                COALESCE(p.id, c.id) AS category_id,
                COALESCE(p.name, c.name) AS name,
                COALESCE(p.default_key, c.default_key) AS default_key,
                COALESCE(p.color, c.color) AS color,
                COALESCE(p.icon, c.icon) AS icon,
                SUM(transactions.amount) AS total, COUNT(*) AS count')
            ->groupByRaw('transactions.currency, transactions.type, COALESCE(p.id, c.id), COALESCE(p.name, c.name), COALESCE(p.default_key, c.default_key), COALESCE(p.color, c.color), COALESCE(p.icon, c.icon)')
            ->orderByDesc('total')
            ->get()
            ->map(fn ($row) => [
                'currency' => $row->currency,
                'type' => $row->type,
                'category_id' => $row->category_id,
                'name' => $row->name,
                'default_key' => $row->default_key,
                'color' => $row->color,
                'icon' => $row->icon,
                'total' => Money::toDecimal((int) $row->total, $row->currency),
                'total_minor' => (int) $row->total,
                'count' => (int) $row->count,
            ]);

        $bucketFormat = $interval === 'month' ? 'YYYY-MM' : 'YYYY-MM-DD';
        $bucket = DB::getDriverName() === 'pgsql'
            ? "to_char(occurred_at AT TIME ZONE 'UTC' AT TIME ZONE ?, '{$bucketFormat}')"
            : ($interval === 'month' ? "strftime('%Y-%m', occurred_at)" : "strftime('%Y-%m-%d', occurred_at)");
        $bindings = DB::getDriverName() === 'pgsql' ? [$tz] : [];

        $series = (clone $base)
            ->selectRaw("{$bucket} AS bucket, currency, type, SUM(amount) AS total", $bindings)
            // Positional grouping: Postgres cannot match a re-bound timezone parameter.
            ->groupByRaw('1, 2, 3')
            ->orderBy('bucket')
            ->get()
            ->groupBy(fn ($row) => $row->bucket.'|'.$row->currency)
            ->map(function ($rows) {
                $first = $rows->first();
                $income = (int) $rows->firstWhere('type', 'income')?->total;
                $expense = (int) $rows->firstWhere('type', 'expense')?->total;

                return [
                    'period' => $first->bucket,
                    'currency' => $first->currency,
                    'income' => Money::toDecimal($income, $first->currency),
                    'expense' => Money::toDecimal($expense, $first->currency),
                    'income_minor' => $income,
                    'expense_minor' => $expense,
                ];
            })
            ->values();

        return response()->json(['data' => [
            'from' => $from->toIso8601String(),
            'to' => $to->toIso8601String(),
            'interval' => $interval,
            'totals' => $currencies,
            'by_category' => $byCategory,
            'series' => $series,
        ]]);
    }
}
