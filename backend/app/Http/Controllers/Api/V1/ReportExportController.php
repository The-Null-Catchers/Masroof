<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Jobs\GenerateReportExport;
use App\Models\ReportExport;
use App\Reports\ReportBuilder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\App;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ReportExportController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $exports = ReportExport::query()->where('user_id', $request->user()->id)->latest()->limit(20)->get();

        return response()->json(['data' => $exports->map(fn (ReportExport $e) => $this->present($e))]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'type' => ['required', Rule::in(ReportBuilder::TYPES)],
            'format' => ['required', Rule::in(ReportExport::FORMATS[$request->input('type')] ?? [])],
            'from' => ['sometimes', 'date_format:Y-m-d', 'required_with:to'],
            'to' => ['sometimes', 'date_format:Y-m-d', 'after_or_equal:from', 'required_with:from'],
            'offset' => ['sometimes', 'integer', 'between:-120,0'],
            'months' => ['sometimes', 'integer', 'between:2,24'],
            'account_id' => ['sometimes', 'ulid', Rule::exists('accounts', 'id')->where('user_id', $request->user()->id)],
            'category_id' => ['sometimes', 'ulid', Rule::exists('categories', 'id')->where('user_id', $request->user()->id)],
            'transaction_type' => ['sometimes', Rule::in(['income', 'expense', 'transfer'])],
        ]);

        if (isset($data['from']) && now()->parse($data['from'])->diffInDays(now()->parse($data['to'])) > 3660) {
            abort(422, __('masroof.range_too_large'));
        }

        $export = new ReportExport([
            'type' => $data['type'],
            'format' => $data['format'],
            'parameters' => [...array_diff_key($data, array_flip(['type', 'format'])), 'locale' => App::getLocale()],
        ]);
        $export->user_id = $request->user()->id;
        $export->save();
        GenerateReportExport::dispatch($export->id);

        return response()->json(['data' => $this->present($export->refresh())], 202);
    }

    public function show(Request $request, ReportExport $export): JsonResponse
    {
        abort_unless($export->user_id === $request->user()->id, 404);

        return response()->json(['data' => $this->present($export)]);
    }

    public function download(Request $request, ReportExport $export): StreamedResponse
    {
        abort_unless($export->user_id === $request->user()->id, 404);
        abort_unless($export->status === 'completed' && $export->file_path && Storage::disk('local')->exists($export->file_path), 404);

        return Storage::disk('local')->download($export->file_path, $export->file_name, [
            'Content-Type' => match ($export->format) {
                'csv' => 'text/csv; charset=UTF-8',
                'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                default => 'application/pdf',
            },
        ]);
    }

    /** @return array<string, mixed> */
    private function present(ReportExport $export): array
    {
        return [
            'id' => $export->id,
            'type' => $export->type,
            'format' => $export->format,
            'status' => $export->status,
            'file_name' => $export->file_name,
            'size' => $export->size,
            'error' => $export->error,
            'created_at' => $export->created_at?->toIso8601String(),
            'completed_at' => $export->completed_at?->toIso8601String(),
            'expires_at' => $export->expires_at?->toIso8601String(),
        ];
    }
}
