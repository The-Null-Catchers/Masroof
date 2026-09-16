"use client";

import { ArrowLeftRight, MoreHorizontal, Plus, ReceiptText, Search } from "lucide-react";
import { useSearchParams } from "next/navigation";
import { useEffect, useState } from "react";
import { toast } from "sonner";

import { EmptyState } from "@/components/common/empty-state";
import { CATEGORY_ICONS, IconBadge } from "@/components/common/finance-icons";
import { PageHeader } from "@/components/common/page-header";
import { Amount } from "@/components/money/amount";
import { TransactionDialog } from "@/components/transactions/transaction-dialog";
import { transactionTitle } from "@/components/transactions/transaction-row";
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
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import {
  useAccounts,
  useCategories,
  useDeleteTransaction,
  useDuplicateTransaction,
  useTransactions,
  type TransactionFilters,
} from "@/hooks/use-finance";
import { describeError } from "@/lib/api/describe";
import { formatDate } from "@/lib/dates";
import { useI18n } from "@/lib/i18n/provider";
import type { Transaction } from "@/lib/types";

const ALL = "all";

export function TransactionsView() {
  const i18n = useI18n();
  const { t, locale, format, categoryLabel } = i18n;
  const params = useSearchParams();
  const [filters, setFilters] = useState<TransactionFilters>({ page: 1, per_page: 20, account_id: params.get("account") ?? undefined });
  const [search, setSearch] = useState("");
  const [dialog, setDialog] = useState<{ open: boolean; tx?: Transaction | null }>({ open: false });
  const [pendingDelete, setPendingDelete] = useState<Transaction | null>(null);

  const { data: accounts = [] } = useAccounts(true);
  const { data: categories = [] } = useCategories();
  const transactions = useTransactions(filters);
  const remove = useDeleteTransaction();
  const duplicate = useDuplicateTransaction();

  async function duplicateTransaction(tx: Transaction) {
    try {
      await duplicate.mutateAsync(tx.id);
      toast.success(t.transactions.duplicated);
    } catch (e) {
      toast.error(describeError(e, t));
    }
  }

  useEffect(() => {
    const handle = setTimeout(() => setFilters((f) => ({ ...f, search: search.trim() || undefined, page: 1 })), 300);
    return () => clearTimeout(handle);
  }, [search]);

  const update = (patch: Partial<TransactionFilters>) => setFilters((f) => ({ ...f, ...patch, page: 1 }));
  const meta = transactions.data?.meta;
  const hasFilters = Boolean(
    filters.type ||
    filters.account_id ||
    filters.category_id ||
    filters.from ||
    filters.to ||
    filters.search ||
    filters.min_amount ||
    filters.max_amount,
  );

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
        title={t.transactions.title}
        actions={
          <Button onClick={() => setDialog({ open: true, tx: null })}>
            <Plus />
            {t.transactions.add}
          </Button>
        }
      />

      <Card className="gap-3 p-4">
        <div className="relative">
          <Search className="absolute inset-y-0 start-3 my-auto size-4 text-muted-foreground" />
          <Input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder={t.transactions.searchPlaceholder}
            className="ps-9"
            aria-label={t.common.search}
          />
        </div>
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4 xl:grid-cols-7">
          <Select value={filters.type ?? ALL} onValueChange={(v) => update({ type: v === ALL ? undefined : v })}>
            <SelectTrigger className="w-full" aria-label={t.transactions.type}>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value={ALL}>{t.common.all}</SelectItem>
              <SelectItem value="expense">{t.transactions.expense}</SelectItem>
              <SelectItem value="income">{t.transactions.income}</SelectItem>
              <SelectItem value="transfer">{t.transactions.transfer}</SelectItem>
            </SelectContent>
          </Select>
          <Select value={filters.account_id ?? ALL} onValueChange={(v) => update({ account_id: v === ALL ? undefined : v })}>
            <SelectTrigger className="w-full" aria-label={t.transactions.account}>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value={ALL}>{`${t.transactions.account}: ${t.common.all}`}</SelectItem>
              {accounts.map((a) => (
                <SelectItem key={a.id} value={a.id}>
                  {a.name}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          <Select value={filters.category_id ?? ALL} onValueChange={(v) => update({ category_id: v === ALL ? undefined : v })}>
            <SelectTrigger className="w-full" aria-label={t.transactions.category}>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value={ALL}>{`${t.transactions.category}: ${t.common.all}`}</SelectItem>
              {categories.map((c) => (
                <SelectItem key={c.id} value={c.id}>
                  {c.parent_id ? "  " : ""}
                  {categoryLabel(c)}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          <Input
            type="date"
            aria-label={t.transactions.from}
            value={filters.from ?? ""}
            onChange={(e) => update({ from: e.target.value || undefined })}
          />
          <Input
            type="date"
            aria-label={t.transactions.to}
            value={filters.to ?? ""}
            min={filters.from}
            onChange={(e) => update({ to: e.target.value || undefined })}
          />
          <Input
            type="number"
            min="0"
            step="any"
            dir="ltr"
            placeholder={t.transactions.minAmount}
            aria-label={t.transactions.minAmount}
            value={filters.min_amount ?? ""}
            onChange={(e) => update({ min_amount: e.target.value || undefined })}
          />
          <Input
            type="number"
            min="0"
            step="any"
            dir="ltr"
            placeholder={t.transactions.maxAmount}
            aria-label={t.transactions.maxAmount}
            value={filters.max_amount ?? ""}
            onChange={(e) => update({ max_amount: e.target.value || undefined })}
          />
        </div>
      </Card>

      <Card className="overflow-hidden p-0">
        {transactions.isLoading ? (
          <div className="space-y-2 p-4">
            {Array.from({ length: 6 }, (_, i) => (
              <Skeleton key={i} className="h-12 w-full" />
            ))}
          </div>
        ) : !transactions.data?.data.length ? (
          <EmptyState
            icon={ReceiptText}
            title={hasFilters ? t.transactions.noResults : t.transactions.empty}
            body={t.transactions.emptyBody}
            action={
              !hasFilters && (
                <Button onClick={() => setDialog({ open: true, tx: null })}>
                  <Plus />
                  {t.transactions.add}
                </Button>
              )
            }
          />
        ) : (
          <div className="overflow-x-auto">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>{t.transactions.details}</TableHead>
                  <TableHead className="hidden md:table-cell">{t.transactions.account}</TableHead>
                  <TableHead className="hidden sm:table-cell">{t.transactions.date}</TableHead>
                  <TableHead className="text-end">{t.transactions.amount}</TableHead>
                  <TableHead className="w-10">
                    <span className="sr-only">{t.common.actions}</span>
                  </TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {transactions.data.data.map((tx) => {
                  const icon =
                    tx.type === "transfer" ? ArrowLeftRight : (CATEGORY_ICONS[tx.category?.icon ?? ""] ?? CATEGORY_ICONS.category);
                  return (
                    <TableRow key={tx.id} className="cursor-pointer" onClick={() => setDialog({ open: true, tx })}>
                      <TableCell>
                        <div className="flex items-center gap-3">
                          <IconBadge icon={icon} color={tx.type === "transfer" ? "var(--transfer)" : tx.category?.color} size={32} />
                          <div className="min-w-0">
                            <p className="truncate font-medium">{transactionTitle(tx, i18n)}</p>
                            <p className="truncate text-xs text-muted-foreground">
                              {tx.type === "transfer" ? (
                                <Badge variant="secondary">{t.transactions.transfer}</Badge>
                              ) : (
                                categoryLabel(tx.category)
                              )}
                              {tx.note ? ` · ${tx.note}` : ""}
                            </p>
                          </div>
                        </div>
                      </TableCell>
                      <TableCell className="hidden text-muted-foreground md:table-cell">{tx.account?.name}</TableCell>
                      <TableCell className="hidden text-muted-foreground sm:table-cell">{formatDate(tx.occurred_at, locale)}</TableCell>
                      <TableCell className="text-end">
                        <Amount
                          minor={tx.type === "expense" ? -tx.amount_minor : tx.amount_minor}
                          currency={tx.currency}
                          tone={tx.type === "transfer" ? "transfer" : tx.type === "income" ? "income" : "expense"}
                          signed={tx.type !== "transfer"}
                          className="font-semibold"
                        />
                      </TableCell>
                      <TableCell onClick={(e) => e.stopPropagation()}>
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" size="icon-sm" aria-label={t.common.actions}>
                              <MoreHorizontal />
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="end">
                            <DropdownMenuItem onSelect={() => setDialog({ open: true, tx })}>{t.common.edit}</DropdownMenuItem>
                            <DropdownMenuItem onSelect={() => duplicateTransaction(tx)}>{t.transactions.duplicate}</DropdownMenuItem>
                            <DropdownMenuItem variant="destructive" onSelect={() => setPendingDelete(tx)}>
                              {t.common.delete}
                            </DropdownMenuItem>
                          </DropdownMenuContent>
                        </DropdownMenu>
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          </div>
        )}
        {meta && meta.last_page > 1 && (
          <div className="flex items-center justify-between border-t px-4 py-3 text-sm">
            <span className="text-muted-foreground">{format(t.common.pageOf, { page: meta.current_page, total: meta.last_page })}</span>
            <div className="flex gap-2">
              <Button
                variant="outline"
                size="sm"
                disabled={meta.current_page <= 1}
                onClick={() => setFilters((f) => ({ ...f, page: (f.page ?? 1) - 1 }))}
              >
                {t.common.previous}
              </Button>
              <Button
                variant="outline"
                size="sm"
                disabled={meta.current_page >= meta.last_page}
                onClick={() => setFilters((f) => ({ ...f, page: (f.page ?? 1) + 1 }))}
              >
                {t.common.next}
              </Button>
            </div>
          </div>
        )}
      </Card>

      <TransactionDialog open={dialog.open} transaction={dialog.tx} onOpenChange={(open) => setDialog((d) => ({ ...d, open }))} />

      <AlertDialog open={!!pendingDelete} onOpenChange={(open) => !open && setPendingDelete(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>{t.common.confirmDelete}</AlertDialogTitle>
            <AlertDialogDescription>{t.common.cannotUndo}</AlertDialogDescription>
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
