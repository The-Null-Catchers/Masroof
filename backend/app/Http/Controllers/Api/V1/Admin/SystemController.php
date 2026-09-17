<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\AdminAuditLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Str;
use Throwable;

/**
 * Service health and failed queue jobs. Job payloads can contain user data,
 * so only the job class, queue and the exception's first line are exposed.
 */
class SystemController extends Controller
{
    public function status(): JsonResponse
    {
        return response()->json(['data' => [
            'database' => $this->check(fn () => DB::select('SELECT 1')),
            'cache' => $this->check(function () {
                // A string round-trip: Redis returns numbers as strings.
                $probe = Str::random(16);
                Cache::put('admin:health', $probe, 5);

                return Cache::get('admin:health') === $probe;
            }),
            'queue' => [
                'connection' => config('queue.default'),
                'pending' => $this->safely(fn () => Queue::size()),
                'failed' => DB::table('failed_jobs')->count(),
            ],
            'ocr_driver' => config('masroof.ocr.driver'),
            'app' => [
                'environment' => app()->environment(),
                'php' => PHP_VERSION,
                'laravel' => app()->version(),
                'time' => now()->toIso8601String(),
            ],
        ]]);
    }

    public function failedJobs(): JsonResponse
    {
        $jobs = DB::table('failed_jobs')->orderByDesc('failed_at')->limit(100)->get();

        return response()->json(['data' => $jobs->map(function ($job) {
            $payload = json_decode((string) $job->payload, true);

            return [
                'uuid' => $job->uuid,
                'queue' => $job->queue,
                'job' => class_basename((string) ($payload['displayName'] ?? 'Unknown')),
                'attempts' => $payload['attempts'] ?? null,
                'error' => Str::limit(strtok((string) $job->exception, "\n") ?: '', 300),
                'failed_at' => Carbon::parse($job->failed_at)->toIso8601String(),
            ];
        })]);
    }

    public function retry(Request $request, string $uuid): JsonResponse
    {
        abort_unless(DB::table('failed_jobs')->where('uuid', $uuid)->exists(), 404);
        Artisan::call('queue:retry', ['id' => [$uuid]]);
        AdminAuditLog::record($request->user(), 'job.retried', null, ['uuid' => $uuid]);

        return response()->json(null, 204);
    }

    public function forget(Request $request, string $uuid): JsonResponse
    {
        abort_unless(DB::table('failed_jobs')->where('uuid', $uuid)->delete() > 0, 404);
        AdminAuditLog::record($request->user(), 'job.deleted', null, ['uuid' => $uuid]);

        return response()->json(null, 204);
    }

    private function check(callable $probe): bool
    {
        return (bool) $this->safely(fn () => $probe() !== false);
    }

    private function safely(callable $probe): mixed
    {
        try {
            return $probe();
        } catch (Throwable) {
            return null;
        }
    }
}
