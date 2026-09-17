"use client";

import { format } from "date-fns";
import { useState, type FormEvent } from "react";
import { toast } from "sonner";

import { Field } from "@/components/common/field";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { useAccounts, useCategories, useSaveRecurring } from "@/hooks/use-finance";
import { describeError } from "@/lib/api/describe";
import { ApiError } from "@/lib/api/errors";
import { useI18n } from "@/lib/i18n/provider";
import { currencySymbol, parseAmount, toDecimal } from "@/lib/money";
import type { Frequency, RecurringTransaction, TransactionType } from "@/lib/types";

export function RecurringDialog({
  open,
  onOpenChange,
  rule,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  rule?: RecurringTransaction | null;
}) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[92dvh] overflow-y-auto sm:max-w-lg">
        <RecurringForm rule={rule} onDone={() => onOpenChange(false)} />
      </DialogContent>
    </Dialog>
  );
}

function RecurringForm({ rule, onDone }: { rule?: RecurringTransaction | null; onDone: () => void }) {
  const { t, locale, categoryLabel } = useI18n();
  const { data: accounts = [] } = useAccounts();
  const { data: categories = [] } = useCategories();
  const save = useSaveRecurring();
  const [form, setForm] = useState(() => ({
    name: rule?.name ?? "",
    type: (rule?.type ?? "expense") as TransactionType,
    account_id: rule?.account_id ?? accounts[0]?.id ?? "",
    category_id: rule?.category_id ?? "",
    transfer_account_id: rule?.transfer_account_id ?? "",
    amount: rule?.amount ?? "",
    merchant: rule?.merchant ?? "",
    frequency: (rule?.frequency ?? "monthly") as Frequency,
    interval: String(rule?.interval ?? 1),
    starts_on: rule?.starts_on ?? format(new Date(), "yyyy-MM-dd"),
    ends_on: rule?.ends_on ?? "",
    mode: rule?.mode ?? "auto",
    remind_days_before: String(rule?.remind_days_before ?? 1),
  }));
  const [errors, setErrors] = useState<Record<string, string>>({});
  const set = <K extends keyof typeof form>(key: K, value: (typeof form)[K]) => setForm((f) => ({ ...f, [key]: value }));

  const accountId = form.account_id || accounts[0]?.id || "";
  const account = accounts.find((a) => a.id === accountId);
  const destination = accounts.find((a) => a.id === form.transfer_account_id);
  const typeCategories = categories.filter((c) => c.type === form.type && !c.archived);

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    const local: Record<string, string> = {};
    if (!form.name.trim()) local.name = t.common.required;
    const minor = account ? parseAmount(form.amount, account.currency) : null;
    if (minor === null || minor <= 0) local.amount = t.common.invalidAmount;
    if (form.type === "transfer" && (!form.transfer_account_id || form.transfer_account_id === accountId))
      local.transfer_account_id = t.transactions.sameAccount;
    if (form.type !== "transfer" && !form.category_id) local.category_id = t.transactions.selectCategory;
    setErrors(local);
    if (Object.keys(local).length || !account || minor === null) return;

    try {
      await save.mutateAsync({
        id: rule?.id,
        payload: {
          name: form.name.trim(),
          type: form.type,
          account_id: accountId,
          category_id: form.type === "transfer" ? null : form.category_id,
          transfer_account_id: form.type === "transfer" ? form.transfer_account_id : null,
          amount: toDecimal(minor, account.currency),
          merchant: form.merchant.trim() || null,
          note: null,
          frequency: form.frequency,
          interval: Math.max(1, Number(form.interval) || 1),
          starts_on: form.starts_on,
          ends_on: form.ends_on || null,
          mode: form.mode,
          remind_days_before: Math.max(0, Number(form.remind_days_before) || 0),
        },
      });
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
        <DialogTitle>{rule ? t.recurring.edit : t.recurring.add}</DialogTitle>
      </DialogHeader>
      <form id="recurring-form" onSubmit={onSubmit} className="space-y-4" noValidate>
        <Tabs value={form.type} onValueChange={(v) => setForm((f) => ({ ...f, type: v as TransactionType, category_id: "" }))}>
          <TabsList className="grid w-full grid-cols-3">
            <TabsTrigger value="expense">{t.transactions.expense}</TabsTrigger>
            <TabsTrigger value="income">{t.transactions.income}</TabsTrigger>
            <TabsTrigger value="transfer">{t.transactions.transfer}</TabsTrigger>
          </TabsList>
        </Tabs>
        <div className="grid gap-3 sm:grid-cols-2">
          <Field id="rec-name" label={t.recurring.name} error={errors.name}>
            <Input id="rec-name" maxLength={80} value={form.name} onChange={(e) => set("name", e.target.value)} />
          </Field>
          <Field id="rec-amount" label={t.transactions.amount} error={errors.amount}>
            <div className="relative">
              <Input
                id="rec-amount"
                dir="ltr"
                inputMode="decimal"
                className="tabular pe-12"
                value={form.amount}
                onChange={(e) => set("amount", e.target.value)}
              />
              {account && (
                <span className="absolute inset-y-0 end-3 grid place-items-center text-sm text-muted-foreground">
                  {currencySymbol(account.currency, locale)}
                </span>
              )}
            </div>
          </Field>
        </div>
        <div className="grid gap-3 sm:grid-cols-2">
          <Field
            id="rec-account"
            label={form.type === "transfer" ? t.transactions.fromAccount : t.transactions.account}
            error={errors.account_id}
          >
            <Select value={accountId} onValueChange={(v) => set("account_id", v)}>
              <SelectTrigger id="rec-account" className="w-full">
                <SelectValue placeholder={t.transactions.selectAccount} />
              </SelectTrigger>
              <SelectContent>
                {accounts.map((a) => (
                  <SelectItem key={a.id} value={a.id}>
                    {a.name} · {a.currency}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </Field>
          {form.type === "transfer" ? (
            <Field id="rec-to" label={t.transactions.toAccount} error={errors.transfer_account_id ?? errors.transfer_amount}>
              <Select value={form.transfer_account_id} onValueChange={(v) => set("transfer_account_id", v)}>
                <SelectTrigger id="rec-to" className="w-full">
                  <SelectValue placeholder={t.transactions.selectAccount} />
                </SelectTrigger>
                <SelectContent>
                  {accounts
                    .filter((a) => a.id !== accountId && (!account || a.currency === account.currency || a.id === destination?.id))
                    .map((a) => (
                      <SelectItem key={a.id} value={a.id}>
                        {a.name} · {a.currency}
                      </SelectItem>
                    ))}
                </SelectContent>
              </Select>
            </Field>
          ) : (
            <Field id="rec-category" label={t.transactions.category} error={errors.category_id}>
              <Select value={form.category_id} onValueChange={(v) => set("category_id", v)}>
                <SelectTrigger id="rec-category" className="w-full">
                  <SelectValue placeholder={t.transactions.selectCategory} />
                </SelectTrigger>
                <SelectContent>
                  {typeCategories.map((c) => (
                    <SelectItem key={c.id} value={c.id}>
                      {categoryLabel(c)}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </Field>
          )}
        </div>
        <div className="grid grid-cols-2 gap-3">
          <Field id="rec-frequency" label={t.recurring.frequency}>
            <Select value={form.frequency} onValueChange={(v) => set("frequency", v as Frequency)}>
              <SelectTrigger id="rec-frequency" className="w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {(["daily", "weekly", "monthly", "yearly"] as const).map((f) => (
                  <SelectItem key={f} value={f}>
                    {t.recurring.frequencies[f]}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </Field>
          <Field id="rec-interval" label={`${t.recurring.every} (${t.recurring.units[form.frequency]})`} error={errors.interval}>
            <Input
              id="rec-interval"
              type="number"
              min={1}
              max={366}
              dir="ltr"
              value={form.interval}
              onChange={(e) => set("interval", e.target.value)}
            />
          </Field>
        </div>
        <div className="grid grid-cols-2 gap-3">
          <Field id="rec-start" label={t.recurring.startsOn} error={errors.starts_on}>
            <Input id="rec-start" type="date" value={form.starts_on} onChange={(e) => set("starts_on", e.target.value)} />
          </Field>
          <Field id="rec-end" label={`${t.recurring.endsOn} (${t.common.optional})`} error={errors.ends_on}>
            <Input id="rec-end" type="date" min={form.starts_on} value={form.ends_on} onChange={(e) => set("ends_on", e.target.value)} />
          </Field>
        </div>
        <div className="grid gap-3 sm:grid-cols-[1fr_10rem]">
          <Field id="rec-mode" label={t.recurring.mode}>
            <Select value={form.mode} onValueChange={(v) => set("mode", v as "auto" | "remind")}>
              <SelectTrigger id="rec-mode" className="w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="auto">{t.recurring.modes.auto}</SelectItem>
                <SelectItem value="remind">{t.recurring.modes.remind}</SelectItem>
              </SelectContent>
            </Select>
          </Field>
          {form.mode === "remind" && (
            <Field id="rec-remind" label={t.recurring.remindBefore}>
              <Input
                id="rec-remind"
                type="number"
                min={0}
                max={14}
                dir="ltr"
                value={form.remind_days_before}
                onChange={(e) => set("remind_days_before", e.target.value)}
              />
            </Field>
          )}
        </div>
        {form.type !== "transfer" && (
          <Field id="rec-merchant" label={`${t.transactions.merchant} (${t.common.optional})`}>
            <Input id="rec-merchant" maxLength={120} value={form.merchant} onChange={(e) => set("merchant", e.target.value)} />
          </Field>
        )}
      </form>
      <DialogFooter>
        <Button variant="outline" onClick={onDone}>
          {t.common.cancel}
        </Button>
        <Button type="submit" form="recurring-form" disabled={save.isPending || !accounts.length}>
          {t.common.save}
        </Button>
      </DialogFooter>
    </>
  );
}
