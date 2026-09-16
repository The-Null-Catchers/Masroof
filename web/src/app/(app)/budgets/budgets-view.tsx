"use client";

import { PiggyBank, Plus } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

import { BudgetCard } from "@/components/budgets/budget-card";
import { BudgetDialog } from "@/components/budgets/budget-dialog";
import { EmptyState } from "@/components/common/empty-state";
import { PageHeader } from "@/components/common/page-header";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { useBudgets, useDeleteBudget } from "@/hooks/use-finance";
import { describeError } from "@/lib/api/describe";
import { useI18n } from "@/lib/i18n/provider";
import type { Budget } from "@/lib/types";

export function BudgetsView() {
  const { t } = useI18n();
  const budgets = useBudgets();
  const remove = useDeleteBudget();
  const [dialog, setDialog] = useState<{ open: boolean; budget?: Budget | null }>({ open: false });
  const [pendingDelete, setPendingDelete] = useState<Budget | null>(null);

  const add = (
    <Button onClick={() => setDialog({ open: true, budget: null })}>
      <Plus />
      {t.budgets.add}
    </Button>
  );

  return (
    <div className="space-y-6">
      <PageHeader title={t.budgets.title} actions={add} />
      {budgets.isLoading ? (
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {Array.from({ length: 3 }, (_, i) => (
            <Skeleton key={i} className="h-56 rounded-xl" />
          ))}
        </div>
      ) : !budgets.data?.length ? (
        <Card>
          <EmptyState icon={PiggyBank} title={t.budgets.empty} body={t.budgets.emptyBody} action={add} />
        </Card>
      ) : (
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {budgets.data.map((budget) => (
            <BudgetCard
              key={budget.id}
              budget={budget}
              onEdit={() => setDialog({ open: true, budget })}
              onDelete={() => setPendingDelete(budget)}
            />
          ))}
        </div>
      )}

      <BudgetDialog open={dialog.open} budget={dialog.budget} onOpenChange={(open) => setDialog((d) => ({ ...d, open }))} />

      <AlertDialog open={!!pendingDelete} onOpenChange={(open) => !open && setPendingDelete(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>{t.common.confirmDelete}</AlertDialogTitle>
            <AlertDialogDescription>{pendingDelete?.name}</AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>{t.common.cancel}</AlertDialogCancel>
            <AlertDialogAction
              variant="destructive"
              onClick={async () => {
                if (!pendingDelete) return;
                try {
                  await remove.mutateAsync(pendingDelete.id);
                  toast.success(t.common.deleted);
                } catch (e) {
                  toast.error(describeError(e, t));
                } finally {
                  setPendingDelete(null);
                }
              }}
            >
              {t.common.delete}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
