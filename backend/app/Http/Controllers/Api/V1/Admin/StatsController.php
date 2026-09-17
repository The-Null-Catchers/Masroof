<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\Receipt;
use App\Models\ReportExport;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

/**
 * Aggregate platform statistics. Deliberately counts only: no amounts,
 * balances, merchants or any other personal financial data.
 */
class StatsController extends Controller
{
    public function __invoke(): JsonResponse
    {
        $now = now();
        $activeSince = $now->copy()->subDays(30);

        $signups = User::query()
            ->where('created_at', '>=', $now->copy()->subDays(29)->startOfDay())
            ->selectRaw('DATE(created_at) AS day, COUNT(*) AS count')
            ->groupByRaw('1')
            ->orderBy('day')
            ->pluck('count', 'day');

        $days = collect(range(29, 0))->map(function (int $ago) use ($now, $signups) {
            $day = $now->copy()->subDays($ago)->toDateString();

            return ['date' => $day, 'count' => (int) ($signups[$day] ?? 0)];
        });

        return response()->json(['data' => [
            'users' => [
                'total' => User::query()->count(),
                'new_7d' => User::query()->where('created_at', '>=', $now->copy()->subDays(7))->count(),
                'new_30d' => User::query()->where('created_at', '>=', $activeSince)->count(),
                'active_30d' => DB::table('personal_access_tokens')
                    ->where('tokenable_type', (new User)->getMorphClass())
                    ->where('last_used_at', '>=', $activeSince)
                    ->distinct()
                    ->count('tokenable_id'),
                'verified' => User::query()->whereNotNull('email_verified_at')->count(),
                'suspended' => User::query()->whereNotNull('suspended_at')->count(),
                'signups_by_day' => $days,
            ],
            'activity' => [
                'transactions_total' => Transaction::query()->count(),
                'transactions_7d' => Transaction::query()->where('created_at', '>=', $now->copy()->subDays(7))->count(),
                'exports_30d' => ReportExport::query()->where('created_at', '>=', $activeSince)->count(),
            ],
            'ocr' => [
                'receipts_30d' => Receipt::query()->where('created_at', '>=', $activeSince)->count(),
                'by_status' => Receipt::query()->where('created_at', '>=', $activeSince)
                    ->selectRaw('status, COUNT(*) AS count')->groupBy('status')->pluck('count', 'status'),
                'by_provider' => Receipt::query()->where('created_at', '>=', $activeSince)->whereNotNull('ocr_provider')
                    ->selectRaw('ocr_provider, COUNT(*) AS count')->groupBy('ocr_provider')->pluck('count', 'ocr_provider'),
            ],
        ]]);
    }
}
