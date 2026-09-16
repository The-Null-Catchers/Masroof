<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Services\AnalyticsService;
use App\Services\Insights\Insight;
use App\Services\Insights\InsightEngine;
use App\Support\Period;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AnalyticsController extends Controller
{
    public function __construct(private readonly AnalyticsService $analytics) {}

    /**
     * Summary for a financial month (offset 0 = current, -1 = previous, …)
     * or an explicit date range, compared with the preceding period.
     */
    public function summary(Request $request): JsonResponse
    {
        $data = $request->validate([
            'currency' => ['sometimes', Rule::in(array_keys(config('masroof.currencies')))],
            'offset' => ['sometimes', 'integer', 'between:-120,0'],
            'from' => ['sometimes', 'date_format:Y-m-d', 'required_with:to'],
            'to' => ['sometimes', 'date_format:Y-m-d', 'after_or_equal:from', 'required_with:from'],
        ]);
        $user = $request->user();

        if (isset($data['from'])) {
            $period = Period::dates($user, $data['from'], $data['to']);
            $previous = $period->previous();
        } else {
            $offset = (int) ($data['offset'] ?? 0);
            $period = Period::financialMonth($user, null, $offset);
            $previous = Period::financialMonth($user, null, $offset - 1);
        }

        return response()->json(['data' => $this->analytics->summary($user, $data['currency'] ?? $user->currency, $period, $previous)]);
    }

    public function trends(Request $request): JsonResponse
    {
        $data = $request->validate([
            'currency' => ['sometimes', Rule::in(array_keys(config('masroof.currencies')))],
            'months' => ['sometimes', 'integer', 'between:2,24'],
        ]);
        $user = $request->user();
        $currency = $data['currency'] ?? $user->currency;

        return response()->json(['data' => [
            'currency' => $currency,
            'months' => $this->analytics->monthlyTrend($user, $currency, (int) ($data['months'] ?? 6)),
        ]]);
    }

    public function insights(Request $request, InsightEngine $engine): JsonResponse
    {
        $data = $request->validate(['currency' => ['sometimes', Rule::in(array_keys(config('masroof.currencies')))]]);
        $user = $request->user();

        return response()->json([
            'data' => array_map(fn (Insight $insight) => $insight->toArray(), $engine->generate($user, $data['currency'] ?? null)),
        ]);
    }
}
