<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\BudgetRequest;
use App\Http\Resources\V1\BudgetResource;
use App\Models\Budget;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;

class BudgetController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $request->validate(['include_archived' => ['sometimes', 'boolean']]);

        $budgets = $request->user()->budgets()
            ->with('categories')
            ->when(! $request->boolean('include_archived'), fn ($q) => $q->whereNull('archived_at'))
            ->orderBy('created_at')
            ->get();

        return BudgetResource::collection($budgets);
    }

    public function store(BudgetRequest $request): JsonResponse
    {
        $budget = DB::transaction(function () use ($request) {
            $budget = $request->user()->budgets()->make($request->toAttributes());
            $budget->alert_thresholds ??= Budget::DEFAULT_THRESHOLDS;
            $budget->save();
            $budget->categories()->sync($request->input('category_ids', []));

            return $budget;
        });

        return (new BudgetResource($budget->load('categories')))->response()->setStatusCode(201);
    }

    public function show(Request $request, Budget $budget): BudgetResource
    {
        $this->authorizeOwner($request, $budget);

        return new BudgetResource($budget->load('categories'));
    }

    public function update(BudgetRequest $request, Budget $budget): BudgetResource
    {
        $this->authorizeOwner($request, $budget);

        DB::transaction(function () use ($request, $budget) {
            $budget->fill($request->toAttributes());
            if ($request->has('archived')) {
                $budget->archived_at = $request->boolean('archived') ? ($budget->archived_at ?? now()) : null;
            }
            $budget->save();
            if ($request->has('category_ids')) {
                $budget->categories()->sync($request->input('category_ids', []));
            }
        });

        return new BudgetResource($budget->refresh()->load('categories'));
    }

    public function destroy(Request $request, Budget $budget): JsonResponse
    {
        $this->authorizeOwner($request, $budget);
        $budget->delete();

        return response()->json(null, 204);
    }

    private function authorizeOwner(Request $request, Budget $budget): void
    {
        abort_unless($budget->user_id === $request->user()->id, 404);
    }
}
