"use client";

import { ArrowLeftRight, MoreHorizontal, Plus, Repeat } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

import { EmptyState } from "@/components/common/empty-state";
import { CATEGORY_ICONS, IconBadge } from "@/components/common/finance-icons";
import { PageHeader } from "@/components/common/page-header";
import { Amount } from "@/components/money/amount";
import { RecurringDialog } from "@/components/recurring/recurring-dialog";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { Skeleton } from "@/components/ui/skeleton";
import { useDeleteRecurring, useRecurring, useSaveRecurring } from "@/hooks/use-finance";
import { describeError } from "@/lib/api/describe";
import { formatDate } from "@/lib/dates";
import { useI18n } from "@/lib/i18n/provider";
import type { RecurringTransaction } from "@/lib/types";

export function RecurringView() {
  const { t, locale, format, categoryLabel } = useI18n();
  const rules = useRecurring();
  const save = useSaveRecurring();
  const remove = useDeleteRecurring();
  const [dialog, setDialog] = useState<{ open: boolean; rule?: RecurringTransaction | null }>({ open: false });

  const add = (
    <Button onClick={() => setDialog({ open: true, rule: null })}>
      <Plus />
      {t.recurring.add}
    </Button>
  );

  const act = async (fn: () => Promise<unknown>) => {
    try {
      await fn();
      toast.success(t.common.saved);
    } catch (e) {
      toast.error(describeError(e, t));
    }
  };

  const schedule = (r: RecurringTransaction) =>
    r.interval === 1 ? t.recurring.frequencies[r.frequency] : `${t.recurring.every} ${r.interval} ${t.recurring.units[r.frequency]}`;

  return (
    <div className="space-y-6">
      <PageHeader title={t.recurring.title} actions={add} />
      {rules.isLoading ? (
        <Skeleton className="h-64 rounded-xl" />
      ) : !rules.data?.length ? (
        <Card>
          <EmptyState icon={Repeat} title={t.recurring.empty} body={t.recurring.emptyBody} action={add} />
        </Card>
      ) : (
        <Card className="divide-y p-0">
          {rules.data.map((r) => {
            const icon = r.type === "transfer" ? ArrowLeftRight : (CATEGORY_ICONS[r.category?.icon ?? ""] ?? CATEGORY_ICONS.category);
            return (
              <div key={r.id} className="flex items-center gap-3 px-4 py-3" data-paused={r.paused || undefined}>
                <IconBadge icon={icon} color={r.type === "transfer" ? "var(--transfer)" : r.category?.color} />
                <div className="min-w-0 flex-1">
                  <p className="flex flex-wrap items-center gap-2 font-medium">
                    {r.name}
                    {r.paused && <Badge variant="secondary">{t.recurring.paused}</Badge>}
                    {r.mode === "remind" && <Badge variant="outline">{t.recurring.modes.remind}</Badge>}
                  </p>
                  <p className="truncate text-xs text-muted-foreground">
                    {schedule(r)}
                    {r.category ? ` · ${categoryLabel(r.category)}` : ""} ·{" "}
                    {r.next_occurrence_on
                      ? format(t.recurring.next, { date: formatDate(r.next_occurrence_on, locale) })
                      : t.recurring.ended}
                  </p>
                </div>
                <Amount
                  minor={r.type === "expense" ? -r.amount_minor : r.amount_minor}
                  currency={r.currency}
                  tone={r.type === "income" ? "income" : r.type === "expense" ? "expense" : "transfer"}
                  signed={r.type !== "transfer"}
                  className="font-semibold"
                />
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button variant="ghost" size="icon-sm" aria-label={t.common.actions}>
                      <MoreHorizontal />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end">
                    <DropdownMenuItem onSelect={() => setDialog({ open: true, rule: r })}>{t.common.edit}</DropdownMenuItem>
                    <DropdownMenuItem onSelect={() => act(() => save.mutateAsync({ id: r.id, payload: { paused: !r.paused } }))}>
                      {r.paused ? t.recurring.resume : t.recurring.pause}
                    </DropdownMenuItem>
                    <DropdownMenuItem variant="destructive" onSelect={() => act(() => remove.mutateAsync(r.id))}>
                      {t.common.delete}
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </div>
            );
          })}
        </Card>
      )}
      <RecurringDialog open={dialog.open} rule={dialog.rule} onOpenChange={(open) => setDialog((d) => ({ ...d, open }))} />
    </div>
  );
}
