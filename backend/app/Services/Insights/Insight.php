<?php

namespace App\Services\Insights;

/**
 * One deterministic observation about a user's finances. `key` selects the
 * translated message (lang/{locale}/insights.php); `params` fill it in.
 */
final readonly class Insight
{
    /**
     * @param  'positive'|'info'|'warning'|'critical'  $severity
     * @param  array<string, string|int|float>  $params
     * @param  array<string, mixed>  $data
     */
    public function __construct(
        public string $key,
        public string $severity,
        public array $params = [],
        public array $data = [],
        public int $priority = 50,
    ) {}

    /** @return array<string, mixed> */
    public function toArray(): array
    {
        return [
            'key' => $this->key,
            'severity' => $this->severity,
            'message' => __("insights.{$this->key}", $this->params),
            'params' => $this->params,
            'data' => $this->data,
        ];
    }
}
