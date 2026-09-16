"use client";

import { Goal as GoalIcon, Plus } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

import { EmptyState } from "@/components/common/empty-state";
import { PageHeader } from "@/components/common/page-header";
import { GoalCard } from "@/components/goals/goal-card";
import { GoalDialog, GoalMoneyDialog } from "@/components/goals/goal-dialogs";
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
import { useDeleteGoal, useGoals } from "@/hooks/use-finance";
import { describeError } from "@/lib/api/describe";
import { useI18n } from "@/lib/i18n/provider";
import type { Goal } from "@/lib/types";

export function GoalsView() {
  const { t } = useI18n();
  const goals = useGoals();
  const remove = useDeleteGoal();
  const [edit, setEdit] = useState<{ open: boolean; goal?: Goal | null }>({ open: false });
  const [money, setMoney] = useState<Goal | null>(null);
  const [pendingDelete, setPendingDelete] = useState<Goal | null>(null);

  const add = (
    <Button onClick={() => setEdit({ open: true, goal: null })}>
      <Plus />
      {t.goals.add}
    </Button>
  );

  return (
    <div className="space-y-6">
      <PageHeader title={t.goals.title} actions={add} />
      {goals.isLoading ? (
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {Array.from({ length: 3 }, (_, i) => (
            <Skeleton key={i} className="h-60 rounded-xl" />
          ))}
        </div>
      ) : !goals.data?.length ? (
        <Card>
          <EmptyState icon={GoalIcon} title={t.goals.empty} body={t.goals.emptyBody} action={add} />
        </Card>
      ) : (
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {goals.data.map((goal) => (
            <GoalCard
              key={goal.id}
              goal={goal}
              onMoney={() => setMoney(goal)}
              onEdit={() => setEdit({ open: true, goal })}
              onDelete={() => setPendingDelete(goal)}
            />
          ))}
        </div>
      )}

      <GoalDialog open={edit.open} goal={edit.goal} onOpenChange={(open) => setEdit((e) => ({ ...e, open }))} />
      <GoalMoneyDialog goal={money} onOpenChange={(open) => !open && setMoney(null)} />

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
