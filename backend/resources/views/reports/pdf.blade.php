@php($rtl = $report->isRtl())
<html lang="{{ $report->locale }}" dir="{{ $rtl ? 'rtl' : 'ltr' }}">
<head>
<style>
    body { font-family: plexarabic; color: #0F172A; font-size: 9.5pt; }
    .header { background: #07463D; color: #ffffff; padding: 14px 18px; border-radius: 10px; }
    .header td { color: #ffffff; vertical-align: middle; }
    .brand { font-size: 13pt; font-weight: bold; }
    .title { font-size: 17pt; font-weight: bold; margin-top: 2px; }
    .subtitle { color: #BFE7DB; font-size: 9pt; }
    .metrics { width: 100%; margin: 14px 0 4px; border-collapse: separate; border-spacing: 6px 0; }
    .metric { background: #F1F7F5; border-radius: 8px; padding: 10px 12px; }
    .metric .label { color: #64748B; font-size: 8pt; }
    .metric .value { font-size: 12.5pt; font-weight: bold; margin-top: 2px; }
    .tone-income { color: #15803D; }
    .tone-expense { color: #DC2626; }
    h2 { font-size: 11.5pt; color: #07463D; margin: 18px 0 6px; padding-bottom: 4px; border-bottom: 2px solid #7FE3C1; }
    table.data { width: 100%; border-collapse: collapse; }
    table.data th { background: #0F7A68; color: #ffffff; font-size: 8.5pt; padding: 6px 7px; text-align: {{ $rtl ? 'right' : 'left' }}; }
    table.data td { padding: 5px 7px; border-bottom: 0.5px solid #E2E8F0; font-size: 8.5pt; }
    table.data tr.odd td { background: #F8FAFC; }
    .num { text-align: {{ $rtl ? 'left' : 'right' }}; white-space: nowrap; }
    .empty { color: #94A3B8; padding: 8px 0; }
</style>
</head>
<body>
<table class="header" width="100%">
    <tr>
        <td width="44"><img src="{{ $logo }}" width="38" height="38" /></td>
        <td>
            <div class="brand">{{ $rtl ? 'مصروف' : 'Masroof' }}</div>
            <div class="title">{{ $report->title }}</div>
            <div class="subtitle"><span dir="ltr">{{ $report->subtitle }}</span></div>
        </td>
    </tr>
</table>

@if (count($report->metrics))
<table class="metrics">
    <tr>
        @foreach ($report->metrics as $metric)
            <td class="metric">
                <div class="label">{{ $metric['label'] }}</div>
                <div class="value {{ isset($metric['tone']) ? 'tone-'.$metric['tone'] : '' }}"><span dir="ltr">{{ $metric['value'] }}</span></div>
            </td>
        @endforeach
    </tr>
</table>
@endif

@foreach ($report->tables as $table)
    <h2>{{ $table->title }}</h2>
    @if (count($table->rows) === 0)
        <div class="empty">{{ $table->emptyText }}</div>
    @else
        <table class="data" repeat_header="1">
            <thead>
                <tr>
                    @foreach ($table->columns as $i => $column)
                        <th class="{{ $table->isNumeric($i) ? 'num' : '' }}">{{ $column }}</th>
                    @endforeach
                </tr>
            </thead>
            <tbody>
                @foreach ($table->rows as $r => $row)
                    <tr class="{{ $r % 2 ? 'odd' : '' }}">
                        @foreach ($row as $i => $cell)
                            {{-- Numbers, signs and % keep left-to-right order inside RTL pages. --}}
                            <td class="{{ $table->isNumeric($i) ? 'num' : '' }}">@if ($table->isNumeric($i) || preg_match('/^[\d\s:\-→+.%]+$/u', (string) $cell))<span dir="ltr">{{ $cell }}</span>@else{{ $cell }}@endif</td>
                        @endforeach
                    </tr>
                @endforeach
            </tbody>
        </table>
    @endif
@endforeach
</body>
</html>
