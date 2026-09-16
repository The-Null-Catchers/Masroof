"use client";

import { CircleCheck, MoreHorizontal, Plane, Car, Heart, House, Laptop, ShieldCheck, Target, type LucideIcon } from "lucide-react";

import { ProgressBar } from "@/components/common/progress-bar";
import { Amount } from "@/components/money/amount";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { formatDate } from "@/lib/dates";
import { useI18n } from "@/lib/i18n/provider";
import { formatMoney } from "@/lib/money";
import type { Goal, GoalKind } from "@/lib/types";

export const GOAL_ICONS: Record<GoalKind, LucideIcon> = {
  emergency_fund: ShieldCheck,
  laptop: Laptop,
  car: Car,
  travel: Plane,
  wedding: Heart,
  home: House,
  custom: Target,
};

export function GoalCard({
  goal,
  onMoney,
  onEdit,
  onDelete,
  compact = false,
}: {
  goal: Goal;
  onMoney?: () => void;
  onEdit?: () => void;
  onDelete?: () => void;
  compact?: boolean;
}) {
  const { t, locale, format } = useI18n();
  const Icon = GOAL_ICONS[goal.kind];
  const tint = goal.color ?? "var(--primary)";
  const p = goal.progress;

  return (
    <Card className={compact ? "gap-3 p-4" : "gap-4 p-5"}>
      <div className="flex items-start gap-3">
        <span
          className="grid size-10 shrink-0 place-items-center rounded-xl"
          style={{ color: tint, background: `color-mix(in oklch, ${tint} 14%, transparent)` }}
        >
          <Icon className="size-5" />
        </span>
        <div className="min-w-0 flex-1">
          <p className="truncate font-semibold">{goal.name}</p>
          <p className="text-xs text-muted-foreground">
            {goal.achieved ? (
              <span className="inline-flex items-center gap-1 text-income">
                <CircleCheck className="size-3.5" />
                {t.goals.achieved}
              </span>
            ) : goal.target_date ? (
              formatDate(goal.target_date, locale)
            ) : (
              t.goals.kinds[goal.kind]
            )}
          </p>
        </div>
        {!compact && (
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
        )}
      </div>

      <div className="flex items-end justify-between gap-2">
        <Amount
          minor={goal.current_amount_minor}
          currency={goal.currency}
          className={compact ? "text-lg font-bold" : "text-2xl font-bold"}
        />
        <span className="text-xs text-muted-foreground">
          {format(t.goals.of, { amount: formatMoney(goal.target_amount_minor, goal.currency, locale) })}
        </span>
      </div>
      <ProgressBar value={p.percent} label={goal.name} />
      <div className="flex flex-wrap justify-between gap-x-3 gap-y-1 text-xs text-muted-foreground">
        <span className="tabular">{Math.round(p.percent)}%</span>
        {!goal.achieved && p.monthly_needed_minor !== null && (
          <span>{format(t.goals.monthlyNeeded, { amount: formatMoney(p.monthly_needed_minor, goal.currency, locale) })}</span>
        )}
        {!goal.achieved && (
          <span>
            {p.expected_completion_date
              ? format(t.goals.expected, { date: formatDate(p.expected_completion_date, locale) })
              : t.goals.noPace}
          </span>
        )}
      </div>
      {onMoney && !compact && (
        <Button variant="secondary" onClick={onMoney}>
          {t.goals.contribute}
        </Button>
      )}
    </Card>
  );
}
