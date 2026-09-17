"use client";

import { PiggyBank, Plus, Scale, TrendingDown, TrendingUp } from "lucide-react";
import Link from "next/link";
import { useState, type ReactNode } from "react";

import { CategoryDonut } from "@/components/charts/category-donut";
import { IncomeExpenseChart, SpendingTrendChart } from "@/components/charts/trend-charts";
import { EmptyState } from "@/components/common/empty-state";
import { InsightList } from "@/components/common/insight-list";
import { ProgressBar } from "@/components/common/progress-bar";
import { GoalCard } from "@/components/goals/goal-card";
import { Amount } from "@/components/money/amount";
import { TransactionDialog } from "@/components/transactions/transaction-dialog";
import { TransactionRow } from "@/components/transactions/transaction-row";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { useAccounts, useDashboard, useMe } from "@/hooks/use-finance";
import { formatDate } from "@/lib/dates";
import { useI18n } from "@/lib/i18n/provider";
import type { Transaction } from "@/lib/types";

function SectionCard({ title, href, children, className }: { title: string; href?: string; children: ReactNode; className?: string }) {
  const { t } = useI18n();
  return (
    <Card className={className}>
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle>{title}</CardTitle>
        {href && (
          <Button variant="link" asChild className="h-auto p-0">
            <Link href={href}>{t.common.seeAll}</Link>
          </Button>
        )}
      </CardHeader>
      <CardContent>{children}</CardContent>
    </Card>
  );
}

export function DashboardView() {
  const { t, format, locale } = useI18n();
  const { data: me } = useMe();
  const accounts = useAccounts();
  const dashboard = useDashboard();
  const [dialog, setDialog] = useState<{ open: boolean; tx?: Transaction | null }>({ open: false });
  const d = dashboard.data;

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

  const currency = d?.currency ?? me?.currency ?? "ILS";
  const primaryNetWorth = d?.net_worth.find((row) => row.currency === currency);
  const otherNetWorth = d?.net_worth.filter((row) => row.currency !== currency) ?? [];

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">{format(t.dashboard.greeting, { name: me?.name.split(" ")[0] ?? "" })}</h1>
          <p className="text-sm text-muted-foreground">
            {d
              ? `${formatDate(d.period.start, locale, { day: "numeric", month: "long" })} – ${formatDate(d.period.end, locale, { day: "numeric", month: "long" })}`
              : t.app.tagline}
          </p>
        </div>
        <Button onClick={() => setDialog({ open: true, tx: null })}>
          <Plus />
          {t.transactions.add}
        </Button>
      </div>

      {/* Hero: balance + month at a glance */}
      <div className="grid gap-4 lg:grid-cols-3">
        <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-brand to-brand-deep p-6 text-white shadow-sm lg:col-span-1">
          <div aria-hidden className="absolute -end-10 -top-10 size-40 rounded-full bg-brand-mint/20 blur-2xl" />
          <p className="text-sm text-white/75">{t.dashboard.netWorth}</p>
          {!d ? (
            <Skeleton className="mt-3 h-10 w-48 bg-white/20" />
          ) : (
            <>
              <Amount
                minor={primaryNetWorth?.total_minor ?? 0}
                currency={currency}
                className="mt-2 block text-3xl font-bold tracking-tight"
              />
              {otherNetWorth.length > 0 && (
                <div className="mt-3 flex flex-wrap gap-x-4 gap-y-1 text-sm text-white/80">
                  {otherNetWorth.map((row) => (
                    <Amount key={row.currency} minor={row.total_minor} currency={row.currency} />
                  ))}
                </div>
              )}
            </>
          )}
          {d?.budget && (
            <div className="mt-6 space-y-2">
              <div className="flex justify-between text-xs text-white/75">
                <span>{t.dashboard.remainingBudget}</span>
                <Amount minor={d.budget.remaining_minor} currency={currency} className="font-semibold text-white" />
              </div>
              <div className="h-1.5 overflow-hidden rounded-full bg-white/20">
                <div
                  className="h-full rounded-full bg-brand-mint"
                  style={{ width: `${Math.min(100, (d.budget.spent_minor / d.budget.amount_minor) * 100)}%` }}
                />
              </div>
            </div>
          )}
        </div>

        <div className="grid grid-cols-2 gap-4 lg:col-span-2">
          {[
            { label: t.dashboard.income, icon: TrendingUp, minor: d?.month.income_minor, tone: "income" as const },
            { label: t.dashboard.expenses, icon: TrendingDown, minor: d?.month.expense_minor, tone: "expense" as const },
            {
              label: t.dashboard.savings,
              icon: PiggyBank,
              minor: d?.month.savings_minor,
              tone: "auto" as const,
              extra: d?.month.savings_rate,
            },
            { label: t.dashboard.remainingBudget, icon: Scale, minor: d?.budget?.remaining_minor, tone: "auto" as const },
          ].map(({ label, icon: Icon, minor, tone, extra }) => (
            <Card key={label} className="gap-2 p-5">
              <p className="flex items-center gap-1.5 text-sm text-muted-foreground">
                <Icon className="size-4" />
                {label}
              </p>
              {!d ? (
                <Skeleton className="h-7 w-28" />
              ) : minor === undefined ? (
                <span className="text-sm text-muted-foreground">{t.dashboard.noBudget}</span>
              ) : (
                <div className="flex flex-wrap items-baseline gap-2">
                  <Amount minor={minor} currency={currency} tone={tone} className="text-xl font-bold" />
                  {extra !== undefined && extra !== null && (
                    <span className="tabular text-xs text-muted-foreground">{Math.round(extra)}%</span>
                  )}
                </div>
              )}
            </Card>
          ))}
        </div>
      </div>

      {d && d.insights.length > 0 && (
        <SectionCard title={t.dashboard.insightsTitle} href="/analytics">
          <InsightList insights={d.insights} empty="" />
        </SectionCard>
      )}

      <div className="grid gap-4 lg:grid-cols-5">
        <SectionCard title={t.analytics.incomeVsExpense} className="lg:col-span-3">
          <div className="h-64">
            {d ? <IncomeExpenseChart months={d.monthly_trend} currency={currency} /> : <Skeleton className="h-full" />}
          </div>
        </SectionCard>
        <SectionCard title={t.dashboard.spendingByCategory} className="lg:col-span-2" href="/analytics">
          {!d ? (
            <Skeleton className="h-48" />
          ) : d.spending_by_category.length ? (
            <CategoryDonut rows={d.spending_by_category} currency={currency} />
          ) : (
            <p className="py-10 text-center text-sm text-muted-foreground">{t.dashboard.noActivity}</p>
          )}
        </SectionCard>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <SectionCard title={t.dashboard.budgetsOverview} href="/budgets">
          {!d ? (
            <Skeleton className="h-40" />
          ) : d.budgets.length ? (
            <ul className="space-y-4">
              {d.budgets.map((b) => (
                <li key={b.id} className="space-y-1.5">
                  <div className="flex items-center justify-between gap-2 text-sm">
                    <span className="truncate font-medium">{b.name}</span>
                    <span className="tabular text-xs text-muted-foreground">{Math.round(b.percent)}%</span>
                  </div>
                  <ProgressBar value={b.percent} tone={b.status} label={b.name} />
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-sm text-muted-foreground">{t.budgets.emptyBody}</p>
          )}
        </SectionCard>
        <SectionCard title={t.analytics.spendingTrend}>
          <div className="h-56">
            {d ? <SpendingTrendChart months={d.monthly_trend} currency={currency} /> : <Skeleton className="h-full" />}
          </div>
        </SectionCard>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <SectionCard title={t.recurring.upcoming} href="/recurring">
          {!d ? (
            <Skeleton className="h-32" />
          ) : d.upcoming_recurring.length ? (
            <ul className="divide-y text-sm">
              {d.upcoming_recurring.map((r) => (
                <li key={r.id} className="flex items-center justify-between gap-3 py-2">
                  <span className="min-w-0">
                    <span className="block truncate font-medium">{r.name}</span>
                    <span className="text-xs text-muted-foreground">
                      {r.next_occurrence_on &&
                        formatDate(r.next_occurrence_on, locale, { weekday: "short", day: "numeric", month: "short" })}
                    </span>
                  </span>
                  <Amount
                    minor={r.type === "expense" ? -r.amount_minor : r.amount_minor}
                    currency={r.currency}
                    tone={r.type === "income" ? "income" : r.type === "expense" ? "expense" : "transfer"}
                    signed={r.type !== "transfer"}
                    className="font-semibold"
                  />
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-sm text-muted-foreground">{t.recurring.noUpcoming}</p>
          )}
        </SectionCard>
      </div>

      <div className="grid gap-4 lg:grid-cols-5">
        <SectionCard title={t.dashboard.goalsProgress} href="/goals" className="lg:col-span-2">
          {!d ? (
            <Skeleton className="h-40" />
          ) : d.goals.length ? (
            <div className="space-y-3">
              {d.goals.map((goal) => (
                <GoalCard key={goal.id} goal={goal} compact />
              ))}
            </div>
          ) : (
            <p className="text-sm text-muted-foreground">{t.goals.emptyBody}</p>
          )}
        </SectionCard>
        <SectionCard title={t.dashboard.recent} href="/transactions" className="lg:col-span-3">
          <div className="-mx-3">
            {!d ? (
              <Skeleton className="mx-3 h-60" />
            ) : d.recent_transactions.length ? (
              d.recent_transactions.map((tx) => <TransactionRow key={tx.id} tx={tx} onClick={() => setDialog({ open: true, tx })} />)
            ) : (
              <p className="px-3 py-6 text-center text-sm text-muted-foreground">{t.transactions.emptyBody}</p>
            )}
          </div>
        </SectionCard>
      </div>

      <TransactionDialog open={dialog.open} transaction={dialog.tx} onOpenChange={(open) => setDialog((s) => ({ ...s, open }))} />
    </div>
  );
}
