"use client";

import { MoreHorizontal } from "lucide-react";

import { ProgressBar } from "@/components/common/progress-bar";
import { Amount } from "@/components/money/amount";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { formatDate } from "@/lib/dates";
import { useI18n } from "@/lib/i18n/provider";
import { formatMoney } from "@/lib/money";
import type { Budget } from "@/lib/types";
import { cn } from "@/lib/utils";

const BADGE = {
  on_track: "bg-income/10 text-income",
  warning: "bg-brand-gold/15 text-brand-gold",
  exceeded: "bg-expense/10 text-expense",
} as const;

export function BudgetCard({ budget, onEdit, onDelete }: { budget: Budget; onEdit: () => void; onDelete: () => void }) {
  const { t, locale, format } = useI18n();
  const p = budget.progress;
  const elapsedPercent = budget.amount_minor ? (p.expected_spent_minor / budget.amount_minor) * 100 : 0;

  return (
    <Card className="gap-4 p-5">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="truncate font-semibold">{budget.name}</p>
          <p className="text-xs text-muted-foreground">
            {t.budgets.periods[budget.period]} · {formatDate(p.period.start, locale, { day: "numeric", month: "short" })} –{" "}
            {formatDate(p.period.end, locale, { day: "numeric", month: "short" })}
          </p>
        </div>
        <div className="flex items-center gap-1">
          <Badge className={cn("border-0", BADGE[p.status])}>{t.budgets.status[p.status]}</Badge>
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="icon-sm" aria-label={t.common.actions}>
                <MoreHorizontal />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuItem onSelect={onEdit}>{t.common.edit}</DropdownMenuItem>
              <DropdownMenuItem variant="destructive" onSelect={onDelete}>
                {t.common.delete}
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      </div>

      <div className="flex items-end justify-between gap-2">
        <div>
          <p className="text-xs text-muted-foreground">{t.budgets.spent}</p>
          <Amount minor={p.spent_minor} currency={budget.currency} className="text-2xl font-bold" />
        </div>
        <p className="tabular text-sm text-muted-foreground">
          {Math.round(p.percent)}% · <Amount minor={budget.amount_minor} currency={budget.currency} />
        </p>
      </div>

      <ProgressBar value={p.percent} tone={p.status} marker={p.days_left > 0 ? elapsedPercent : undefined} label={budget.name} />

      <div className="grid grid-cols-2 gap-3 text-sm">
        <div>
          <p className="text-xs text-muted-foreground">{t.budgets.remaining}</p>
          {p.remaining_minor >= 0 ? (
            <Amount minor={p.remaining_minor} currency={budget.currency} className="font-semibold" />
          ) : (
            <span className="font-semibold text-expense">
              {format(t.budgets.overBy, { amount: formatMoney(-p.remaining_minor, budget.currency, locale) })}
            </span>
          )}
        </div>
        <div className="text-end">
          <p className="text-xs text-muted-foreground">
            {p.days_left > 0 ? format(t.budgets.daysLeft, { days: p.days_left }) : t.budgets.ended}
          </p>
          {p.days_left > 0 && (
            <span className="font-semibold">
              {format(t.budgets.perDay, { amount: formatMoney(p.safe_to_spend_daily_minor, budget.currency, locale) })}
            </span>
          )}
        </div>
      </div>
      {p.days_left > 0 && p.projected_spent_minor > budget.amount_minor && (
        <p className="text-xs text-expense">
          {format(t.budgets.projected, { amount: formatMoney(p.projected_spent_minor, budget.currency, locale) })}
        </p>
      )}
    </Card>
  );
}
