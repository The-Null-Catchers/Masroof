"use client";

import { Download, FileSpreadsheet, FileText, LoaderCircle } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

import { Field } from "@/components/common/field";
import { PageHeader } from "@/components/common/page-header";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { useCreateExport, useExports } from "@/hooks/use-finance";
import { describeError } from "@/lib/api/describe";
import { formatDate, periodRange } from "@/lib/dates";
import { useI18n } from "@/lib/i18n/provider";
import type { ReportType } from "@/lib/types";
import { cn } from "@/lib/utils";

const FORMATS: Record<ReportType, ("pdf" | "xlsx" | "csv")[]> = {
  monthly: ["pdf", "xlsx"],
  transactions: ["csv", "xlsx", "pdf"],
  budgets: ["pdf", "xlsx", "csv"],
  income_expense: ["pdf", "xlsx", "csv"],
  categories: ["pdf", "xlsx", "csv"],
};

export function ReportsView() {
  const { t, locale, format } = useI18n();
  const exports = useExports();
  const create = useCreateExport();
  const month = periodRange("month");
  const [type, setType] = useState<ReportType>("monthly");
  const [fileFormat, setFileFormat] = useState<"pdf" | "xlsx" | "csv">("pdf");
  const [offset, setOffset] = useState("0");
  const [months, setMonths] = useState("12");
  const [from, setFrom] = useState(month.from);
  const [to, setTo] = useState(month.to);

  const usesRange = type === "transactions" || type === "categories";

  async function generate() {
    const payload: Record<string, string | number> = { type, format: FORMATS[type].includes(fileFormat) ? fileFormat : FORMATS[type][0] };
    if (type === "monthly") payload.offset = Number(offset);
    if (type === "income_expense") payload.months = Number(months);
    if (usesRange) Object.assign(payload, { from, to });
    try {
      await create.mutateAsync(payload);
    } catch (e) {
      toast.error(describeError(e, t));
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader title={t.reports.title} description={t.reports.description} />
      <div className="grid gap-4 lg:grid-cols-5">
        <Card className="lg:col-span-3">
          <CardContent className="space-y-5 pt-6">
            <div className="grid gap-2 sm:grid-cols-2">
              {(Object.keys(FORMATS) as ReportType[]).map((key) => (
                <button
                  key={key}
                  type="button"
                  aria-pressed={type === key}
                  onClick={() => {
                    setType(key);
                    if (!FORMATS[key].includes(fileFormat)) setFileFormat(FORMATS[key][0]);
                  }}
                  className={cn(
                    "rounded-xl border p-3 text-start transition-colors hover:bg-muted",
                    type === key && "border-primary bg-primary/5",
                  )}
                >
                  <p className="text-sm font-semibold">{t.reports.types[key]}</p>
                  <p className="mt-1 text-xs leading-relaxed text-muted-foreground">{t.reports.typeHints[key]}</p>
                </button>
              ))}
            </div>

            <div className="grid gap-3 sm:grid-cols-3">
              <Field id="report-format" label={t.reports.format}>
                <Select value={fileFormat} onValueChange={(v) => setFileFormat(v as typeof fileFormat)}>
                  <SelectTrigger id="report-format" className="w-full">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {FORMATS[type].map((f) => (
                      <SelectItem key={f} value={f}>
                        {f === "xlsx" ? "Excel" : f.toUpperCase()}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </Field>
              {type === "monthly" && (
                <Field id="report-month" label={t.reports.period}>
                  <Select value={offset} onValueChange={setOffset}>
                    <SelectTrigger id="report-month" className="w-full">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {[0, -1, -2, -3, -4, -5].map((o) => (
                        <SelectItem key={o} value={String(o)}>
                          {o === 0
                            ? t.analytics.thisMonth
                            : o === -1
                              ? t.analytics.previousMonth
                              : format(t.analytics.monthsAgo, { count: -o })}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </Field>
              )}
              {type === "income_expense" && (
                <Field id="report-months" label={t.reports.period}>
                  <Select value={months} onValueChange={setMonths}>
                    <SelectTrigger id="report-months" className="w-full">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {[3, 6, 12, 24].map((m) => (
                        <SelectItem key={m} value={String(m)}>
                          {format(t.reports.lastMonths, { count: m })}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </Field>
              )}
              {usesRange && (
                <>
                  <Field id="report-from" label={t.transactions.from}>
                    <Input id="report-from" type="date" value={from} onChange={(e) => setFrom(e.target.value)} />
                  </Field>
                  <Field id="report-to" label={t.transactions.to}>
                    <Input id="report-to" type="date" min={from} value={to} onChange={(e) => setTo(e.target.value)} />
                  </Field>
                </>
              )}
            </div>
            <Button onClick={generate} disabled={create.isPending}>
              {create.isPending ? <LoaderCircle className="animate-spin" /> : <Download />}
              {t.reports.generate}
            </Button>
          </CardContent>
        </Card>

        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>{t.reports.recent}</CardTitle>
          </CardHeader>
          <CardContent>
            {!exports.data?.length ? (
              <p className="text-sm text-muted-foreground">{t.reports.noExports}</p>
            ) : (
              <ul className="divide-y">
                {exports.data.map((e) => {
                  const Icon = e.format === "pdf" ? FileText : FileSpreadsheet;
                  return (
                    <li key={e.id} className="flex items-center gap-3 py-3">
                      <Icon className="size-5 shrink-0 text-primary" />
                      <div className="min-w-0 flex-1">
                        <p className="truncate text-sm font-medium">{t.reports.types[e.type]}</p>
                        <p className="text-xs text-muted-foreground">
                          {e.format.toUpperCase()} · {formatDate(e.created_at, locale, { dateStyle: "medium", timeStyle: "short" })}
                        </p>
                      </div>
                      {e.status === "completed" ? (
                        <Button variant="outline" size="sm" asChild>
                          <a href={`/api/backend/reports/exports/${e.id}/download`} download={e.file_name ?? undefined}>
                            <Download />
                            {t.reports.download}
                          </a>
                        </Button>
                      ) : e.status === "failed" ? (
                        <span className="text-xs text-expense">{t.reports.failed}</span>
                      ) : (
                        <span className="inline-flex items-center gap-1 text-xs text-muted-foreground">
                          <LoaderCircle className="size-3.5 animate-spin" />
                          {t.reports.preparing}
                        </span>
                      )}
                    </li>
                  );
                })}
              </ul>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
