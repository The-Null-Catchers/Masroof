"use client";

import { Plus, TrendingDown, TrendingUp, Scale } from "lucide-react";
import Link from "next/link";
import { useState } from "react";
import { Bar, BarChart, CartesianGrid, Cell, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";

import { EmptyState } from "@/components/common/empty-state";
import { Amount } from "@/components/money/amount";
import { TransactionDialog } from "@/components/transactions/transaction-dialog";
import { TransactionRow } from "@/components/transactions/transaction-row";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { useAccounts, useMe, useNetWorth, useReport, useTransactions } from "@/hooks/use-finance";
import { periodRange, type PeriodKey } from "@/lib/dates";
import { useI18n } from "@/lib/i18n/provider";
import { exponentOf, formatMoney } from "@/lib/money";
import type { Transaction } from "@/lib/types";

export function DashboardView() {
  const { t, format, locale, categoryLabel, dir } = useI18n();
  const [period, setPeriod] = useState<PeriodKey>("month");
  const [dialog, setDialog] = useState<{ open: boolean; tx?: Transaction | null }>({ open: false });
  const range = periodRange(period);

  const { data: me } = useMe();
  const accounts = useAccounts();
  const netWorth = useNetWorth();
  const report = useReport(range.from, range.to);
  const recent = useTransactions({ per_page: 6 });

  const currency = me?.currency ?? netWorth.data?.[0]?.currency ?? "SAR";
  const totals = report.data?.totals.find((row) => row.currency === currency) ?? report.data?.totals[0];
  const reportCurrency = totals?.currency ?? currency;
  const scale = 10 ** exponentOf(reportCurrency);

  const series = (report.data?.series ?? [])
    .filter((row) => row.currency === reportCurrency)
    .map((row) => ({ period: row.period, income: row.income_minor / scale, expense: row.expense_minor / scale }));
  const spending = (report.data?.by_category ?? []).filter((row) => row.type === "expense" && row.currency === reportCurrency);
  const spendTotal = spending.reduce((sum, row) => sum + row.total_minor, 0);

  if (accounts.data && accounts.data.length === 0) {
    return (
      <Card>
        <EmptyState
          brand
          title={t.dashboard.emptyTitle}
          body={t.dashboard.emptyBody}
          action={
            <Button asChild>
              <Link href="/accounts?new=1">
                <Plus />
                {t.accounts.add}
              </Link>
            </Button>
          }
        />
      </Card>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">{format(t.dashboard.greeting, { name: me?.name.split(" ")[0] ?? "" })}</h1>
          <p className="text-sm text-muted-foreground">{t.app.tagline}</p>
        </div>
        <div className="flex items-center gap-2">
          <Select value={period} onValueChange={(v) => setPeriod(v as PeriodKey)}>
            <SelectTrigger className="w-40" aria-label="Period">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {(Object.keys(t.dashboard.period) as PeriodKey[]).map((key) => (
                <SelectItem key={key} value={key}>
                  {t.dashboard.period[key]}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          <Button onClick={() => setDialog({ open: true, tx: null })}>
            <Plus />
            {t.transactions.add}
          </Button>
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <div className="rounded-xl bg-gradient-to-br from-brand to-brand-deep p-5 text-white shadow-sm">
          <p className="text-sm text-white/75">{t.dashboard.netWorth}</p>
          {netWorth.isLoading ? (
            <Skeleton className="mt-3 h-8 w-40 bg-white/20" />
          ) : (
            netWorth.data?.map((row) => (
              <Amount key={row.currency} minor={row.total_minor} currency={row.currency} className="mt-2 block text-2xl font-bold" />
            ))
          )}
        </div>
        <StatCard label={t.dashboard.income} icon={TrendingUp} loading={report.isLoading}>
          {totals && <Amount minor={totals.income_minor} currency={reportCurrency} tone="income" className="text-xl font-bold" />}
        </StatCard>
        <StatCard label={t.dashboard.expenses} icon={TrendingDown} loading={report.isLoading}>
          {totals && <Amount minor={totals.expense_minor} currency={reportCurrency} tone="expense" className="text-xl font-bold" />}
        </StatCard>
        <StatCard label={t.dashboard.net} icon={Scale} loading={report.isLoading}>
          {totals && <Amount minor={totals.net_minor} currency={reportCurrency} tone="auto" signed className="text-xl font-bold" />}
        </StatCard>
      </div>

      <div className="grid gap-4 lg:grid-cols-5">
        <Card className="lg:col-span-3">
          <CardHeader>
            <CardTitle>{t.dashboard.cashflow}</CardTitle>
          </CardHeader>
          <CardContent className="h-72">
            {report.isLoading ? (
              <Skeleton className="h-full w-full" />
            ) : series.length === 0 ? (
              <p className="grid h-full place-items-center text-sm text-muted-foreground">{t.dashboard.noActivity}</p>
            ) : (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={dir === "rtl" ? [...series].reverse() : series} margin={{ top: 4, right: 4, left: 4, bottom: 0 }}>
                  <CartesianGrid vertical={false} strokeDasharray="3 3" stroke="var(--border)" />
                  <XAxis
                    dataKey="period"
                    tickLine={false}
                    axisLine={false}
                    fontSize={11}
                    tickFormatter={(v: string) => v.slice(report.data?.interval === "month" ? 2 : 5)}
                  />
                  <YAxis orientation={dir === "rtl" ? "right" : "left"} tickLine={false} axisLine={false} fontSize={11} width={56} />
                  <Tooltip
                    cursor={{ fill: "var(--muted)" }}
                    contentStyle={{ background: "var(--popover)", border: "1px solid var(--border)", borderRadius: 8, fontSize: 12 }}
                    formatter={(value, name) => [
                      formatMoney(Math.round(Number(value ?? 0) * scale), reportCurrency, locale),
                      name === "income" ? t.dashboard.income : t.dashboard.expenses,
                    ]}
                  />
                  <Bar dataKey="income" fill="var(--income)" radius={[4, 4, 0, 0]} maxBarSize={28} />
                  <Bar dataKey="expense" fill="var(--expense)" radius={[4, 4, 0, 0]} maxBarSize={28} />
                </BarChart>
              </ResponsiveContainer>
            )}
          </CardContent>
        </Card>

        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>{t.dashboard.spendingByCategory}</CardTitle>
          </CardHeader>
          <CardContent>
            {report.isLoading ? (
              <Skeleton className="h-60 w-full" />
            ) : spending.length === 0 ? (
              <p className="py-16 text-center text-sm text-muted-foreground">{t.dashboard.noActivity}</p>
            ) : (
              <div className="space-y-4">
                <div className="h-40">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie
                        data={spending}
                        dataKey="total_minor"
                        nameKey="name"
                        innerRadius={48}
                        outerRadius={72}
                        paddingAngle={2}
                        strokeWidth={0}
                      >
                        {spending.map((row, index) => (
                          <Cell key={row.category_id ?? index} fill={row.color ?? `var(--chart-${(index % 5) + 1})`} />
                        ))}
                      </Pie>
                    </PieChart>
                  </ResponsiveContainer>
                </div>
                <ul className="space-y-2">
                  {spending.slice(0, 5).map((row, index) => (
                    <li key={row.category_id ?? index} className="flex items-center gap-2 text-sm">
                      <span
                        className="size-2.5 shrink-0 rounded-full"
                        style={{ background: row.color ?? `var(--chart-${(index % 5) + 1})` }}
                      />
                      <span className="min-w-0 flex-1 truncate">{categoryLabel(row)}</span>
                      <span className="tabular text-xs text-muted-foreground">
                        {spendTotal ? Math.round((row.total_minor / spendTotal) * 100) : 0}%
                      </span>
                      <Amount minor={row.total_minor} currency={row.currency} className="font-medium" />
                    </li>
                  ))}
                </ul>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle>{t.dashboard.recent}</CardTitle>
          <Button variant="link" asChild className="h-auto p-0">
            <Link href="/transactions">{t.common.seeAll}</Link>
          </Button>
        </CardHeader>
        <CardContent className="px-3">
          {recent.isLoading ? (
            <div className="space-y-2 px-3">
              {Array.from({ length: 4 }, (_, i) => (
                <Skeleton key={i} className="h-12 w-full" />
              ))}
            </div>
          ) : recent.data?.data.length ? (
            recent.data.data.map((tx) => <TransactionRow key={tx.id} tx={tx} onClick={() => setDialog({ open: true, tx })} />)
          ) : (
            <p className="px-3 py-6 text-center text-sm text-muted-foreground">{t.transactions.emptyBody}</p>
          )}
        </CardContent>
      </Card>

      <TransactionDialog open={dialog.open} transaction={dialog.tx} onOpenChange={(open) => setDialog((d) => ({ ...d, open }))} />
    </div>
  );
}

function StatCard({
  label,
  icon: Icon,
  loading,
  children,
}: {
  label: string;
  icon: typeof Plus;
  loading: boolean;
  children: React.ReactNode;
}) {
  return (
    <Card className="gap-2 p-5">
      <p className="flex items-center gap-1.5 text-sm text-muted-foreground">
        <Icon className="size-4" />
        {label}
      </p>
      {loading ? <Skeleton className="h-7 w-32" /> : (children ?? <span className="text-xl text-muted-foreground">—</span>)}
    </Card>
  );
}
