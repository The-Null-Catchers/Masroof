<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\GoalRequest;
use App\Http\Resources\V1\GoalResource;
use App\Models\Goal;
use App\Models\GoalTransaction;
use App\Services\GoalService;
use App\Support\Money;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class GoalController extends Controller
{
    public function __construct(private readonly GoalService $service) {}

    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate(['include_archived' => ['sometimes', 'boolean']]);

        return GoalResource::collection(
            $request->user()->goals()
                ->when(! $request->boolean('include_archived'), fn ($q) => $q->whereNull('archived_at'))
                ->orderByRaw('achieved_at IS NOT NULL')
                ->orderBy('target_date')
                ->orderBy('created_at')
                ->get(),
        );
    }

    public function store(GoalRequest $request): JsonResponse
    {
        $goal = $request->user()->goals()->create($request->toAttributes());

        return (new GoalResource($goal->refresh()))->response()->setStatusCode(201);
    }

    public function show(Request $request, Goal $goal): GoalResource
    {
        $this->authorizeOwner($request, $goal);

        return new GoalResource($goal);
    }

    public function update(GoalRequest $request, Goal $goal): GoalResource
    {
        $this->authorizeOwner($request, $goal);
        $goal->fill($request->toAttributes());
        if ($request->has('archived')) {
            $goal->archived_at = $request->boolean('archived') ? ($goal->archived_at ?? now()) : null;
        }
        // Editing the target can complete or reopen the goal.
        $goal->achieved_at = $goal->current_amount >= $goal->target_amount ? ($goal->achieved_at ?? now()) : null;
        $goal->save();

        return new GoalResource($goal);
    }

    public function destroy(Request $request, Goal $goal): JsonResponse
    {
        $this->authorizeOwner($request, $goal);
        $goal->delete();

        return response()->json(null, 204);
    }

    public function entries(Request $request, Goal $goal): JsonResponse
    {
        $this->authorizeOwner($request, $goal);

        $entries = $goal->entries()->latest('occurred_at')->limit(200)->get()
            ->map(fn (GoalTransaction $entry) => $this->entryArray($entry, $goal));

        return response()->json(['data' => $entries]);
    }

    public function addEntry(Request $request, Goal $goal): JsonResponse
    {
        $this->authorizeOwner($request, $goal);
        $data = $request->validate([
            'type' => ['required', Rule::in(['contribution', 'withdrawal'])],
            'amount' => ['required'],
            'occurred_at' => ['sometimes', 'date'],
            'note' => ['sometimes', 'nullable', 'string', 'max:255'],
        ]);

        $exp = Money::exponent($goal->currency);
        $amount = (string) $data['amount'];
        if (! preg_match(Money::pattern($exp), $amount) || Money::toMinor($amount, $goal->currency) <= 0) {
            throw ValidationException::withMessages(['amount' => __('masroof.invalid_amount', ['decimals' => $exp])]);
        }

        $entry = $this->service->addEntry(
            $goal,
            $data['type'],
            Money::toMinor($amount, $goal->currency),
            isset($data['occurred_at']) ? CarbonImmutable::parse($data['occurred_at'])->utc() : CarbonImmutable::now(),
            $data['note'] ?? null,
        );

        return response()->json([
            'data' => $this->entryArray($entry, $goal),
            'goal' => new GoalResource($goal->refresh()),
        ], 201);
    }

    public function deleteEntry(Request $request, Goal $goal, GoalTransaction $entry): JsonResponse
    {
        $this->authorizeOwner($request, $goal);
        abort_unless($entry->goal_id === $goal->id, 404);
        $this->service->deleteEntry($entry);

        return response()->json(['goal' => new GoalResource($goal->refresh())]);
    }

    /** @return array<string, mixed> */
    private function entryArray(GoalTransaction $entry, Goal $goal): array
    {
        return [
            'id' => $entry->id,
            'type' => $entry->type,
            'amount' => Money::toDecimal($entry->amount, $goal->currency),
            'amount_minor' => $entry->amount,
            'occurred_at' => $entry->occurred_at->toIso8601String(),
            'note' => $entry->note,
        ];
    }

    private function authorizeOwner(Request $request, Goal $goal): void
    {
        abort_unless($goal->user_id === $request->user()->id, 404);
    }
}
