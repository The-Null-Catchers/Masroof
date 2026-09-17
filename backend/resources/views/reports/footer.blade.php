<table width="100%" style="font-family: plexarabic; font-size: 7.5pt; color: #94A3B8; border-top: 0.5px solid #E2E8F0;">
    <tr>
        <td>{{ __('reports.generated', ['date' => now()->toDateTimeString()]) }}</td>
        <td style="text-align: {{ $report->isRtl() ? 'left' : 'right' }};">{PAGENO} / {nbpg}</td>
    </tr>
</table>
