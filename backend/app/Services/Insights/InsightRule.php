<?php

namespace App\Services\Insights;

interface InsightRule
{
    /** @return array<int, Insight> */
    public function evaluate(InsightContext $context): array;
}
