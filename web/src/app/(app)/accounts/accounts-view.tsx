"use client";

import { Archive, ArchiveRestore, MoreHorizontal, Pencil, Plus, Trash2, Wallet } from "lucide-react";
import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { useState } from "react";
import { toast } from "sonner";

import { AccountDialog } from "@/components/accounts/account-dialog";
import { EmptyState } from "@/components/common/empty-state";
import { ACCOUNT_TYPE_ICONS, IconBadge } from "@/components/common/finance-icons";
import { PageHeader } from "@/components/common/page-header";
import { Amount } from "@/components/money/amount";
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
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import { Switch } from "@/components/ui/switch";
import { useAccounts, useDeleteAccount, useNetWorth, useSaveAccount } from "@/hooks/use-finance";
import { describeError } from "@/lib/api/describe";
import { useI18n } from "@/lib/i18n/provider";
import type { Account } from "@/lib/types";

export function AccountsView() {
  const { t } = useI18n();
  const params = useSearchParams();
  const [showArchived, setShowArchived] = useState(false);
  const [dialog, setDialog] = useState<{ open: boolean; account?: Account | null }>(() => ({
    open: params.get("new") !== null,
    account: null,
  }));
  const [pendingDelete, setPendingDelete] = useState<Account | null>(null);
  const accounts = useAccounts(showArchived);
  const netWorth = useNetWorth();
  const save = useSaveAccount();
  const remove = useDeleteAccount();

  async function toggleArchive(account: Account) {
    try {
      await save.mutateAsync({ id: account.id, payload: { archived: !account.archived } });
      toast.success(t.common.saved);
    } catch (e) {
      toast.error(describeError(e, t));
    }
  }

  async function confirmDelete() {
    if (!pendingDelete) return;
    try {
      await remove.mutateAsync(pendingDelete.id);
      toast.success(t.common.deleted);
    } catch (e) {
      toast.error(describeError(e, t));
    } finally {
      setPendingDelete(null);
    }
  }

  return (
    <div className="space-y-6">
      <PageHeader
        title={t.accounts.title}
        actions={
          <>
            <div className="flex items-center gap-2 pe-2">
              <Switch id="show-archived" checked={showArchived} onCheckedChange={setShowArchived} />
              <Label htmlFor="show-archived" className="text-sm font-normal">
                {t.accounts.showArchived}
              </Label>
            </div>
            <Button onClick={() => setDialog({ open: true, account: null })}>
              <Plus />
              {t.accounts.add}
            </Button>
          </>
        }
      />

      {netWorth.data && netWorth.data.length > 0 && (
        <div className="flex flex-wrap items-center gap-x-8 gap-y-2 rounded-xl bg-gradient-to-br from-brand to-brand-deep p-5 text-white">
          <span className="text-sm text-white/75">{t.dashboard.netWorth}</span>
          {netWorth.data.map((row) => (
            <Amount key={row.currency} minor={row.total_minor} currency={row.currency} className="text-2xl font-bold" />
          ))}
        </div>
      )}

      {accounts.isLoading ? (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {Array.from({ length: 3 }, (_, i) => (
            <Skeleton key={i} className="h-36 w-full rounded-xl" />
          ))}
        </div>
      ) : !accounts.data?.length ? (
        <Card>
          <EmptyState
            icon={Wallet}
            title={t.accounts.empty}
            body={t.accounts.emptyBody}
            action={
              <Button onClick={() => setDialog({ open: true, account: null })}>
                <Plus />
                {t.accounts.add}
              </Button>
            }
          />
        </Card>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {accounts.data.map((account) => (
            <Card key={account.id} className="gap-4 p-5" data-archived={account.archived || undefined}>
              <div className="flex items-start justify-between gap-3">
                <div className="flex min-w-0 items-center gap-3">
                  <IconBadge icon={ACCOUNT_TYPE_ICONS[account.type]} color={account.color} size={40} />
                  <div className="min-w-0">
                    <p className="truncate font-semibold">{account.name}</p>
                    <p className="text-xs text-muted-foreground">
                      {t.accounts.types[account.type]} · {account.currency}
                    </p>
                  </div>
                </div>
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button variant="ghost" size="icon-sm" aria-label={t.common.actions}>
                      <MoreHorizontal />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end">
                    <DropdownMenuItem onSelect={() => setDialog({ open: true, account })}>
                      <Pencil />
                      {t.common.edit}
                    </DropdownMenuItem>
                    <DropdownMenuItem onSelect={() => toggleArchive(account)}>
                      {account.archived ? <ArchiveRestore /> : <Archive />}
                      {account.archived ? t.accounts.unarchive : t.accounts.archive}
                    </DropdownMenuItem>
                    <DropdownMenuSeparator />
                    <DropdownMenuItem variant="destructive" onSelect={() => setPendingDelete(account)}>
                      <Trash2 />
                      {t.common.delete}
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </div>
              <div className="flex items-end justify-between gap-2">
                <Amount minor={account.balance_minor} currency={account.currency} tone="auto" className="text-2xl font-bold" />
                {account.archived && <Badge variant="secondary">{t.accounts.archived}</Badge>}
              </div>
              <Button variant="link" asChild className="h-auto justify-start p-0 text-xs">
                <Link href={`/transactions?account=${account.id}`}>{t.transactions.title}</Link>
              </Button>
            </Card>
          ))}
        </div>
      )}

      <AccountDialog open={dialog.open} account={dialog.account} onOpenChange={(open) => setDialog((d) => ({ ...d, open }))} />

      <AlertDialog open={!!pendingDelete} onOpenChange={(open) => !open && setPendingDelete(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>{t.common.confirmDelete}</AlertDialogTitle>
            <AlertDialogDescription>{t.accounts.deleteWarning}</AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>{t.common.cancel}</AlertDialogCancel>
            <AlertDialogAction variant="destructive" onClick={confirmDelete}>
              {t.common.delete}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
