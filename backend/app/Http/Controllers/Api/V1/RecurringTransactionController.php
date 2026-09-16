<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\RecurringTransactionRequest;
use App\Http\Resources\V1\RecurringTransactionResource;
use App\Models\RecurringTransaction;
use App\Services\RecurrenceSchedule;
use App\Services\RecurringService;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;

class RecurringTransactionController extends Controller
{
    public function __construct(private readonly RecurringService $service) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        return RecurringTransactionResource::collection(
            $request->user()->recurringTransactions()
                ->with('category')
                ->orderByRaw('paused_at IS NOT NULL')
                ->orderBy('next_occurrence_on')
                ->get(),
        );
    }

    public function store(RecurringTransactionRequest $request): JsonResponse
    {
        $rule = DB::transaction(function () use ($request) {
            $rule = new RecurringTransaction($request->toAttributes());
            $rule->user_id = $request->user()->id;
            $rule->paused_at = $request->boolean('paused') ? now() : null;
            $rule->setRelation('user', $request->user());
            $this->service->reschedule($rule);
            $rule->save();

            return $rule;
        });

        // Generate anything already due (e.g. a rule starting today).
        $this->service->process($rule);

        return (new RecurringTransactionResource($rule->refresh()->load('category')))->response()->setStatusCode(201);
    }

    public function show(Request $request, RecurringTransaction $recurring): RecurringTransactionResource
    {
        $this->authorizeOwner($request, $recurring);

        return new RecurringTransactionResource($recurring->load('category'));
    }

    public function update(RecurringTransactionRequest $request, RecurringTransaction $recurring): RecurringTransactionResource
    {
        $this->authorizeOwner($request, $recurring);

        DB::transaction(function () use ($request, $recurring) {
            $scheduleChanged = $request->hasAny(['frequency', 'interval', 'starts_on', 'ends_on']);
            $recurring->fill($request->toAttributes());
            if ($request->has('paused')) {
                $recurring->paused_at = $request->boolean('paused') ? ($recurring->paused_at ?? now()) : null;
            }
            if ($scheduleChanged) {
                // Resume from today (never regenerate past dates) on the new schedule.
                $today = $this->service->today($recurring);
                $recurring->next_occurrence_on = app(RecurrenceSchedule::class)->nextOnOrAfter(
                    $recurring,
                    $today->max(CarbonImmutable::parse($recurring->starts_on->toDateString())),
                );
            }
            $recurring->save();
        });

        $this->service->process($recurring);

        return new RecurringTransactionResource($recurring->refresh()->load('category'));
    }

    public function destroy(Request $request, RecurringTransaction $recurring): JsonResponse
    {
        $this->authorizeOwner($request, $recurring);
        // Transactions already created are real history and are kept.
        $recurring->delete();

        return response()->json(null, 204);
    }

    /** Next occurrences across all active rules, soonest first. */
    public function upcoming(Request $request): JsonResponse
    {
        $request->validate(['days' => ['sometimes', 'integer', 'between:1,90']]);
        $until = now($request->user()->timezone)->addDays((int) $request->input('days', 30))->toDateString();

        $rules = $request->user()->recurringTransactions()
            ->with('category')
            ->whereNull('paused_at')
            ->whereNotNull('next_occurrence_on')
            ->where('next_occurrence_on', '<=', $until)
            ->orderBy('next_occurrence_on')
            ->limit(20)
            ->get();

        return response()->json(['data' => RecurringTransactionResource::collection($rules)->toArray($request)]);
    }

    private function authorizeOwner(Request $request, RecurringTransaction $rule): void
    {
        abort_unless($rule->user_id === $request->user()->id, 404);
    }
}
