"use client";

import { ArrowDownRight, ArrowUpRight } from "lucide-react";
import { useState, type ReactNode } from "react";

import { BalanceTrendChart, IncomeExpenseChart, SpendingTrendChart } from "@/components/charts/trend-charts";
import { InsightList } from "@/components/common/insight-list";
import { PageHeader } from "@/components/common/page-header";
import { ProgressBar } from "@/components/common/progress-bar";
import { Amount } from "@/components/money/amount";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { useAnalytics, useInsights, useTrends } from "@/hooks/use-finance";
import { formatDate } from "@/lib/dates";
import { useI18n } from "@/lib/i18n/provider";
import { cn } from "@/lib/utils";

function Change({ value, invert = false }: { value: number | null | undefined; invert?: boolean }) {
  if (value === null || value === undefined) return null;
  const good = invert ? value <= 0 : value >= 0;
  const Icon = value >= 0 ? ArrowUpRight : ArrowDownRight;
  return (
    <span className={cn("tabular inline-flex items-center gap-0.5 text-xs font-medium", good ? "text-income" : "text-expense")}>
      <Icon className="size-3.5" />
      {Math.abs(value)}%
    </span>
  );
}

function Stat({ label, children, change }: { label: string; children: ReactNode; change?: ReactNode }) {
  return (
    <Card className="gap-1.5 p-5">
      <p className="text-sm text-muted-foreground">{label}</p>
      <div className="flex flex-wrap items-baseline gap-2">{children}</div>
      {change}
    </Card>
  );
}

export function AnalyticsView() {
  const { t, locale, format, categoryLabel } = useI18n();
  const [offset, setOffset] = useState(0);
  const summary = useAnalytics(offset);
  const trends = useTrends(6);
  const insights = useInsights();
  const s = summary.data;
  const currency = s?.currency ?? trends.data?.currency ?? "ILS";

  const periodLabel = (o: number) =>
    o === 0 ? t.analytics.thisMonth : o === -1 ? t.analytics.previousMonth : format(t.analytics.monthsAgo, { count: -o });
  const maxCategory = Math.max(1, ...(s?.categories ?? []).map((c) => Math.max(c.total, c.previous_total ?? 0)));
  const fixedTotal = s ? s.fixed_vs_variable.fixed + s.fixed_vs_variable.variable : 0;

  return (
    <div className="space-y-6">
      <PageHeader
        title={t.analytics.title}
        description={s ? `${formatDate(s.period.start, locale)} – ${formatDate(s.period.end, locale)}` : undefined}
        actions={
          <Select value={String(offset)} onValueChange={(v) => setOffset(Number(v))}>
            <SelectTrigger className="w-44" aria-label={t.analytics.period}>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {[0, -1, -2, -3, -4, -5].map((o) => (
                <SelectItem key={o} value={String(o)}>
                  {periodLabel(o)}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        }
      />

      {!s ? (
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          {Array.from({ length: 4 }, (_, i) => (
            <Skeleton key={i} className="h-28 rounded-xl" />
          ))}
        </div>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <Stat label={t.dashboard.income} change={<Change value={s.changes.income} />}>
            <Amount minor={s.income} currency={currency} tone="income" className="text-xl font-bold" />
          </Stat>
          <Stat label={t.dashboard.expenses} change={<Change value={s.changes.expense} invert />}>
            <Amount minor={s.expense} currency={currency} tone="expense" className="text-xl font-bold" />
          </Stat>
          <Stat label={t.analytics.savingsRate}>
            <span className="tabular text-xl font-bold">{s.savings_rate === null ? "—" : `${Math.round(s.savings_rate)}%`}</span>
            <Amount minor={s.savings} currency={currency} tone="auto" signed className="text-sm text-muted-foreground" />
          </Stat>
          <Stat label={t.analytics.avgDaily}>
            <Amount minor={s.average_daily_spending} currency={currency} className="text-xl font-bold" />
          </Stat>
        </div>
      )}

      <div className="grid gap-4 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>{t.analytics.incomeVsExpense}</CardTitle>
          </CardHeader>
          <CardContent className="h-72">
            {trends.data ? <IncomeExpenseChart months={trends.data.months} currency={currency} /> : <Skeleton className="h-full" />}
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle>{t.analytics.insights}</CardTitle>
          </CardHeader>
          <CardContent>
            {insights.data ? <InsightList insights={insights.data} empty={t.analytics.noInsights} /> : <Skeleton className="h-40" />}
          </CardContent>
        </Card>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>{t.analytics.spendingTrend}</CardTitle>
          </CardHeader>
          <CardContent className="h-64">
            {trends.data ? <SpendingTrendChart months={trends.data.months} currency={currency} /> : <Skeleton className="h-full" />}
          </CardContent>
        </Card>
        <Card>
          <CardHeader>
            <CardTitle>{t.analytics.balanceTrend}</CardTitle>
          </CardHeader>
          <CardContent className="h-64">
            {trends.data ? <BalanceTrendChart months={trends.data.months} currency={currency} /> : <Skeleton className="h-full" />}
          </CardContent>
        </Card>
      </div>

      {s && (
        <div className="grid gap-4 lg:grid-cols-5">
          <Card className="lg:col-span-3">
            <CardHeader className="flex flex-row flex-wrap items-center justify-between gap-2">
              <CardTitle>{t.analytics.categoryComparison}</CardTitle>
              <div className="flex items-center gap-3 text-xs text-muted-foreground">
                <span className="inline-flex items-center gap-1.5">
                  <span className="size-2.5 rounded-full bg-primary" />
                  {t.analytics.thisPeriod}
                </span>
                <span className="inline-flex items-center gap-1.5">
                  <span className="size-2.5 rounded-full bg-muted-foreground/40" />
                  {t.analytics.lastPeriod}
                </span>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              {!s.categories.length && <p className="text-sm text-muted-foreground">{t.analytics.noData}</p>}
              {s.categories.slice(0, 8).map((row, index) => (
                <div key={row.category_id ?? index} className="space-y-1.5">
                  <div className="flex items-center justify-between gap-2 text-sm">
                    <span className="min-w-0 truncate font-medium">{categoryLabel(row)}</span>
                    <span className="flex items-center gap-2">
                      <Change value={row.change} invert />
                      <Amount minor={row.total} currency={currency} className="font-semibold" />
                    </span>
                  </div>
                  <div className="space-y-1">
                    <ProgressBar value={(row.total / maxCategory) * 100} label={categoryLabel(row)} />
                    <div
                      className="h-1 rounded-full bg-muted-foreground/40"
                      style={{ width: `${((row.previous_total ?? 0) / maxCategory) * 100}%` }}
                    />
                  </div>
                </div>
              ))}
            </CardContent>
          </Card>

          <div className="space-y-4 lg:col-span-2">
            <Card>
              <CardHeader>
                <CardTitle>{t.analytics.fixedVsVariable}</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex h-3 overflow-hidden rounded-full bg-muted" role="img" aria-label={t.analytics.fixedVsVariable}>
                  <div className="bg-transfer" style={{ width: `${fixedTotal ? (s.fixed_vs_variable.fixed / fixedTotal) * 100 : 0}%` }} />
                  <div className="flex-1 bg-brand-gold" />
                </div>
                <div className="flex justify-between text-sm">
                  <span className="inline-flex items-center gap-1.5">
                    <span className="size-2.5 rounded-full bg-transfer" />
                    {t.analytics.fixed}
                    <Amount minor={s.fixed_vs_variable.fixed} currency={currency} className="font-semibold" />
                  </span>
                  <span className="inline-flex items-center gap-1.5">
                    <span className="size-2.5 rounded-full bg-brand-gold" />
                    {t.analytics.variable}
                    <Amount minor={s.fixed_vs_variable.variable} currency={currency} className="font-semibold" />
                  </span>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>{t.analytics.largestExpenses}</CardTitle>
              </CardHeader>
              <CardContent>
                <ul className="divide-y text-sm">
                  {s.largest_expenses.map((e) => (
                    <li key={e.id} className="flex items-center justify-between gap-3 py-2">
                      <span className="min-w-0">
                        <span className="block truncate font-medium">
                          {e.merchant ?? categoryLabel({ name: e.category, default_key: e.default_key })}
                        </span>
                        <span className="text-xs text-muted-foreground">
                          {formatDate(e.occurred_at, locale, { day: "numeric", month: "short" })}
                        </span>
                      </span>
                      <Amount minor={e.amount} currency={currency} className="font-semibold" />
                    </li>
                  ))}
                </ul>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>{t.analytics.topMerchants}</CardTitle>
              </CardHeader>
              <CardContent>
                <ul className="divide-y text-sm">
                  {s.top_merchants.map((m) => (
                    <li key={m.merchant} className="flex items-center justify-between gap-3 py-2">
                      <span className="min-w-0">
                        <span className="block truncate font-medium">{m.merchant}</span>
                        <span className="text-xs text-muted-foreground">{format(t.analytics.visits, { count: m.count })}</span>
                      </span>
                      <Amount minor={m.total} currency={currency} className="font-semibold" />
                    </li>
                  ))}
                </ul>
              </CardContent>
            </Card>
          </div>
        </div>
      )}
    </div>
  );
}
