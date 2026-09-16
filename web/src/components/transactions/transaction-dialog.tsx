"use client";

import { format } from "date-fns";
import { useMemo, useState, type FormEvent } from "react";
import { toast } from "sonner";

import { Field } from "@/components/common/field";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectGroup, SelectItem, SelectLabel, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Textarea } from "@/components/ui/textarea";
import { useAccounts, useCategories, useSaveTransaction, type TransactionPayload } from "@/hooks/use-finance";
import { describeError } from "@/lib/api/describe";
import { ApiError } from "@/lib/api/errors";
import { useI18n } from "@/lib/i18n/provider";
import { currencySymbol, parseAmount, toDecimal } from "@/lib/money";
import type { Transaction, TransactionType } from "@/lib/types";

interface Props {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  transaction?: Transaction | null;
  defaultAccountId?: string;
}

const empty = {
  type: "expense" as TransactionType,
  account_id: "",
  transfer_account_id: "",
  category_id: "",
  amount: "",
  transfer_amount: "",
  date: "",
  payee: "",
  note: "",
};

function initialForm(transaction: Transaction | null | undefined, defaultAccountId?: string) {
  if (!transaction) return { ...empty, account_id: defaultAccountId ?? "", date: format(new Date(), "yyyy-MM-dd'T'HH:mm") };
  return {
    type: transaction.type,
    account_id: transaction.account_id,
    transfer_account_id: transaction.transfer_account_id ?? "",
    category_id: transaction.category_id ?? "",
    amount: transaction.amount,
    transfer_amount: transaction.transfer_amount ?? "",
    date: format(new Date(transaction.occurred_at), "yyyy-MM-dd'T'HH:mm"),
    payee: transaction.payee ?? "",
    note: transaction.note ?? "",
  };
}

export function TransactionDialog({ open, onOpenChange, transaction, defaultAccountId }: Props) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[92dvh] overflow-y-auto sm:max-w-lg">
        {/* Mounted per opening, so form state starts from the selected transaction. */}
        <TransactionForm transaction={transaction} defaultAccountId={defaultAccountId} onDone={() => onOpenChange(false)} />
      </DialogContent>
    </Dialog>
  );
}

function TransactionForm({
  transaction,
  defaultAccountId,
  onDone,
}: {
  transaction?: Transaction | null;
  defaultAccountId?: string;
  onDone: () => void;
}) {
  const { t, locale, categoryLabel } = useI18n();
  const { data: accounts = [] } = useAccounts(true);
  const { data: categories = [] } = useCategories();
  const save = useSaveTransaction();
  const [form, setForm] = useState(() => initialForm(transaction, defaultAccountId));
  const [errors, setErrors] = useState<Record<string, string>>({});

  const activeAccounts = accounts.filter((a) => !a.archived || a.id === form.account_id || a.id === form.transfer_account_id);
  const account = accounts.find((a) => a.id === form.account_id) ?? (activeAccounts.length === 1 ? activeAccounts[0] : undefined);
  const destination = accounts.find((a) => a.id === form.transfer_account_id);
  const crossCurrency = form.type === "transfer" && account && destination && account.currency !== destination.currency;
  const accountId = form.account_id || account?.id || "";

  const grouped = useMemo(() => {
    const ofType = categories.filter((c) => c.type === form.type && !c.archived);
    return ofType.filter((c) => !c.parent_id).map((parent) => ({ parent, children: ofType.filter((c) => c.parent_id === parent.id) }));
  }, [categories, form.type]);

  const set = <K extends keyof typeof form>(key: K, value: (typeof form)[K]) => setForm((f) => ({ ...f, [key]: value }));

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    const local: Record<string, string> = {};
    if (!account) local.account_id = t.transactions.selectAccount;
    const minor = account ? parseAmount(form.amount, account.currency) : null;
    if (!form.amount) local.amount = t.common.required;
    else if (minor === null) local.amount = t.common.invalidAmount;
    else if (minor <= 0) local.amount = t.common.amountPositive;
    if (form.type === "transfer") {
      if (!form.transfer_account_id) local.transfer_account_id = t.transactions.selectAccount;
      else if (form.transfer_account_id === accountId) local.transfer_account_id = t.transactions.sameAccount;
      if (crossCurrency && parseAmount(form.transfer_amount, destination!.currency) === null)
        local.transfer_amount = t.common.invalidAmount;
    } else if (!form.category_id) {
      local.category_id = t.transactions.selectCategory;
    }
    setErrors(local);
    if (Object.keys(local).length || !account || minor === null) return;

    const payload: TransactionPayload = {
      type: form.type,
      account_id: account.id,
      amount: toDecimal(minor, account.currency),
      occurred_at: new Date(form.date).toISOString(),
      note: form.note.trim() || null,
      category_id: form.type === "transfer" ? null : form.category_id,
      transfer_account_id: form.type === "transfer" ? form.transfer_account_id : null,
      payee: form.type === "transfer" ? null : form.payee.trim() || null,
      ...(crossCurrency
        ? { transfer_amount: toDecimal(parseAmount(form.transfer_amount, destination!.currency)!, destination!.currency) }
        : {}),
    };

    try {
      await save.mutateAsync({ id: transaction?.id, payload });
      toast.success(t.common.saved);
      onDone();
    } catch (e) {
      if (e instanceof ApiError && Object.keys(e.fieldErrors).length) {
        setErrors(Object.fromEntries(Object.entries(e.fieldErrors).map(([k, v]) => [k, v[0]])));
      } else {
        toast.error(describeError(e, t));
      }
    }
  }

  return (
    <>
      <DialogHeader>
        <DialogTitle>{transaction ? t.transactions.edit : t.transactions.add}</DialogTitle>
      </DialogHeader>
      {accounts.length === 0 ? (
        <p className="py-6 text-center text-sm text-muted-foreground">{t.transactions.needAccount}</p>
      ) : (
        <form id="transaction-form" onSubmit={onSubmit} className="space-y-4" noValidate>
          <Tabs value={form.type} onValueChange={(v) => setForm((f) => ({ ...f, type: v as TransactionType, category_id: "" }))}>
            <TabsList className="grid w-full grid-cols-3">
              <TabsTrigger value="expense">{t.transactions.expense}</TabsTrigger>
              <TabsTrigger value="income">{t.transactions.income}</TabsTrigger>
              <TabsTrigger value="transfer">{t.transactions.transfer}</TabsTrigger>
            </TabsList>
          </Tabs>

          <Field id="amount" label={t.transactions.amount} error={errors.amount}>
            <div className="relative">
              <Input
                id="amount"
                inputMode="decimal"
                dir="ltr"
                autoFocus
                value={form.amount}
                onChange={(e) => set("amount", e.target.value)}
                aria-invalid={!!errors.amount}
                className="tabular h-12 pe-16 text-center text-2xl font-semibold"
                placeholder="0.00"
              />
              {account && (
                <span className="absolute inset-y-0 end-3 grid place-items-center text-sm text-muted-foreground">
                  {currencySymbol(account.currency, locale)}
                </span>
              )}
            </div>
          </Field>

          <div className="grid gap-4 sm:grid-cols-2">
            <Field
              id="account"
              label={form.type === "transfer" ? t.transactions.fromAccount : t.transactions.account}
              error={errors.account_id}
            >
              <Select value={accountId} onValueChange={(v) => set("account_id", v)}>
                <SelectTrigger id="account" className="w-full" aria-invalid={!!errors.account_id}>
                  <SelectValue placeholder={t.transactions.selectAccount} />
                </SelectTrigger>
                <SelectContent>
                  {activeAccounts.map((a) => (
                    <SelectItem key={a.id} value={a.id}>
                      {a.name} · {a.currency}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </Field>

            {form.type === "transfer" ? (
              <Field id="to-account" label={t.transactions.toAccount} error={errors.transfer_account_id}>
                <Select value={form.transfer_account_id} onValueChange={(v) => set("transfer_account_id", v)}>
                  <SelectTrigger id="to-account" className="w-full" aria-invalid={!!errors.transfer_account_id}>
                    <SelectValue placeholder={t.transactions.selectAccount} />
                  </SelectTrigger>
                  <SelectContent>
                    {activeAccounts
                      .filter((a) => a.id !== accountId)
                      .map((a) => (
                        <SelectItem key={a.id} value={a.id}>
                          {a.name} · {a.currency}
                        </SelectItem>
                      ))}
                  </SelectContent>
                </Select>
              </Field>
            ) : (
              <Field id="category" label={t.transactions.category} error={errors.category_id}>
                <Select value={form.category_id} onValueChange={(v) => set("category_id", v)}>
                  <SelectTrigger id="category" className="w-full" aria-invalid={!!errors.category_id}>
                    <SelectValue placeholder={t.transactions.selectCategory} />
                  </SelectTrigger>
                  <SelectContent>
                    {grouped.map(({ parent, children }) => (
                      <SelectGroup key={parent.id}>
                        {children.length > 0 && <SelectLabel>{categoryLabel(parent)}</SelectLabel>}
                        <SelectItem value={parent.id}>{categoryLabel(parent)}</SelectItem>
                        {children.map((child) => (
                          <SelectItem key={child.id} value={child.id} className="ps-6">
                            {categoryLabel(child)}
                          </SelectItem>
                        ))}
                      </SelectGroup>
                    ))}
                  </SelectContent>
                </Select>
              </Field>
            )}
          </div>

          {crossCurrency && (
            <Field
              id="transfer-amount"
              label={t.transactions.amountReceived.replace("{currency}", destination!.currency)}
              error={errors.transfer_amount}
            >
              <Input
                id="transfer-amount"
                inputMode="decimal"
                dir="ltr"
                value={form.transfer_amount}
                onChange={(e) => set("transfer_amount", e.target.value)}
                className="tabular"
              />
            </Field>
          )}

          <div className="grid gap-4 sm:grid-cols-2">
            <Field id="date" label={t.transactions.date} error={errors.occurred_at}>
              <Input id="date" type="datetime-local" value={form.date} onChange={(e) => set("date", e.target.value)} />
            </Field>
            {form.type !== "transfer" && (
              <Field id="payee" label={`${t.transactions.payee} (${t.common.optional})`} error={errors.payee}>
                <Input id="payee" maxLength={120} value={form.payee} onChange={(e) => set("payee", e.target.value)} />
              </Field>
            )}
          </div>

          <Field id="note" label={`${t.transactions.note} (${t.common.optional})`} error={errors.note}>
            <Textarea id="note" rows={2} maxLength={1000} value={form.note} onChange={(e) => set("note", e.target.value)} />
          </Field>
        </form>
      )}
      <DialogFooter>
        <Button variant="outline" onClick={onDone}>
          {t.common.cancel}
        </Button>
        <Button type="submit" form="transaction-form" disabled={save.isPending || accounts.length === 0}>
          {save.isPending ? t.common.loading : t.common.save}
        </Button>
      </DialogFooter>
    </>
  );
}
