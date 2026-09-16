"use client";

import { Trash2 } from "lucide-react";
import { useState, type FormEvent } from "react";
import { toast } from "sonner";

import { Field } from "@/components/common/field";
import { PALETTE } from "@/components/common/finance-icons";
import { Amount } from "@/components/money/amount";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Textarea } from "@/components/ui/textarea";
import { useAccounts, useAddGoalEntry, useDeleteGoalEntry, useGoalEntries, useMe, useSaveGoal } from "@/hooks/use-finance";
import { describeError } from "@/lib/api/describe";
import { ApiError } from "@/lib/api/errors";
import { formatDate } from "@/lib/dates";
import { useI18n } from "@/lib/i18n/provider";
import { CURRENCIES, parseAmount, toDecimal } from "@/lib/money";
import type { Goal, GoalKind } from "@/lib/types";

const KINDS: GoalKind[] = ["emergency_fund", "laptop", "car", "travel", "wedding", "home", "custom"];
const NONE = "none";

export function GoalDialog({ open, onOpenChange, goal }: { open: boolean; onOpenChange: (open: boolean) => void; goal?: Goal | null }) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <GoalForm goal={goal} onDone={() => onOpenChange(false)} />
      </DialogContent>
    </Dialog>
  );
}

function GoalForm({ goal, onDone }: { goal?: Goal | null; onDone: () => void }) {
  const { t } = useI18n();
  const { data: me } = useMe();
  const { data: accounts = [] } = useAccounts();
  const save = useSaveGoal();
  const [form, setForm] = useState(() => ({
    name: goal?.name ?? "",
    kind: goal?.kind ?? ("custom" as GoalKind),
    currency: goal?.currency ?? me?.currency ?? "ILS",
    target_amount: goal?.target_amount ?? "",
    target_date: goal?.target_date ?? "",
    account_id: goal?.account_id ?? NONE,
    color: goal?.color ?? PALETTE[0],
    notes: goal?.notes ?? "",
  }));
  const [errors, setErrors] = useState<Record<string, string>>({});

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    const local: Record<string, string> = {};
    if (!form.name.trim()) local.name = t.common.required;
    const target = parseAmount(form.target_amount, form.currency);
    if (target === null || target <= 0) local.target_amount = t.common.invalidAmount;
    setErrors(local);
    if (Object.keys(local).length || target === null) return;

    try {
      await save.mutateAsync({
        id: goal?.id,
        payload: {
          name: form.name.trim(),
          kind: form.kind,
          ...(goal ? {} : { currency: form.currency }),
          target_amount: toDecimal(target, form.currency),
          target_date: form.target_date || null,
          account_id: form.account_id === NONE ? null : form.account_id,
          color: form.color,
          notes: form.notes.trim() || null,
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
        <DialogTitle>{goal ? t.goals.edit : t.goals.add}</DialogTitle>
      </DialogHeader>
      <form id="goal-form" onSubmit={onSubmit} className="space-y-4" noValidate>
        <Field id="goal-name" label={t.goals.name} error={errors.name}>
          <Input id="goal-name" maxLength={60} value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
        </Field>
        <Field id="goal-kind" label={t.goals.kind}>
          <Select value={form.kind} onValueChange={(kind) => setForm({ ...form, kind: kind as GoalKind })}>
            <SelectTrigger id="goal-kind" className="w-full">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {KINDS.map((kind) => (
                <SelectItem key={kind} value={kind}>
                  {t.goals.kinds[kind]}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </Field>
        <div className="grid grid-cols-2 gap-3">
          <Field id="goal-target" label={t.goals.target} error={errors.target_amount}>
            <Input
              id="goal-target"
              dir="ltr"
              inputMode="decimal"
              className="tabular"
              value={form.target_amount}
              onChange={(e) => setForm({ ...form, target_amount: e.target.value })}
            />
          </Field>
          <Field id="goal-currency" label={t.budgets.currency}>
            <Select value={form.currency} disabled={!!goal} onValueChange={(currency) => setForm({ ...form, currency })}>
              <SelectTrigger id="goal-currency" className="w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {CURRENCIES.map((code) => (
                  <SelectItem key={code} value={code}>
                    {code}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </Field>
        </div>
        <div className="grid grid-cols-2 gap-3">
          <Field id="goal-date" label={`${t.goals.targetDate} (${t.common.optional})`} error={errors.target_date}>
            <Input
              id="goal-date"
              type="date"
              value={form.target_date}
              onChange={(e) => setForm({ ...form, target_date: e.target.value })}
            />
          </Field>
          <Field id="goal-account" label={`${t.goals.linkedAccount} (${t.common.optional})`}>
            <Select value={form.account_id} onValueChange={(account_id) => setForm({ ...form, account_id })}>
              <SelectTrigger id="goal-account" className="w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value={NONE}>—</SelectItem>
                {accounts.map((a) => (
                  <SelectItem key={a.id} value={a.id}>
                    {a.name}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </Field>
        </div>
        <Field id="goal-notes" label={`${t.accounts.notes} (${t.common.optional})`}>
          <Textarea
            id="goal-notes"
            rows={2}
            maxLength={1000}
            value={form.notes}
            onChange={(e) => setForm({ ...form, notes: e.target.value })}
          />
        </Field>
      </form>
      <DialogFooter>
        <Button variant="outline" onClick={onDone}>
          {t.common.cancel}
        </Button>
        <Button type="submit" form="goal-form" disabled={save.isPending}>
          {t.common.save}
        </Button>
      </DialogFooter>
    </>
  );
}

/** Add or withdraw money and review the goal's history. */
export function GoalMoneyDialog({ goal, onOpenChange }: { goal: Goal | null; onOpenChange: (open: boolean) => void }) {
  return (
    <Dialog open={!!goal} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[92dvh] overflow-y-auto sm:max-w-md">
        {goal && <GoalMoneyForm key={goal.id} goal={goal} onDone={() => onOpenChange(false)} />}
      </DialogContent>
    </Dialog>
  );
}

function GoalMoneyForm({ goal, onDone }: { goal: Goal; onDone: () => void }) {
  const { t, locale } = useI18n();
  const entries = useGoalEntries(goal.id);
  const add = useAddGoalEntry();
  const remove = useDeleteGoalEntry();
  const [type, setType] = useState<"contribution" | "withdrawal">("contribution");
  const [amount, setAmount] = useState("");
  const [note, setNote] = useState("");
  const [error, setError] = useState<string>();

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    const minor = parseAmount(amount, goal.currency);
    if (minor === null || minor <= 0) return setError(t.common.invalidAmount);
    setError(undefined);
    try {
      await add.mutateAsync({ goalId: goal.id, type, amount: toDecimal(minor, goal.currency), note: note.trim() || null });
      toast.success(t.common.saved);
      onDone();
    } catch (e) {
      setError(e instanceof ApiError ? (e.field("amount") ?? describeError(e, t)) : describeError(e, t));
    }
  }

  return (
    <>
      <DialogHeader>
        <DialogTitle>{goal.name}</DialogTitle>
      </DialogHeader>
      <form id="goal-money-form" onSubmit={onSubmit} className="space-y-4">
        <Tabs value={type} onValueChange={(v) => setType(v as typeof type)}>
          <TabsList className="grid w-full grid-cols-2">
            <TabsTrigger value="contribution">{t.goals.contribute}</TabsTrigger>
            <TabsTrigger value="withdrawal">{t.goals.withdraw}</TabsTrigger>
          </TabsList>
        </Tabs>
        <Field id="goal-money-amount" label={t.transactions.amount} error={error}>
          <Input
            id="goal-money-amount"
            autoFocus
            dir="ltr"
            inputMode="decimal"
            className="tabular h-11 text-lg"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
          />
        </Field>
        <Field id="goal-money-note" label={`${t.transactions.note} (${t.common.optional})`}>
          <Input id="goal-money-note" maxLength={255} value={note} onChange={(e) => setNote(e.target.value)} />
        </Field>
      </form>
      <DialogFooter>
        <Button variant="outline" onClick={onDone}>
          {t.common.cancel}
        </Button>
        <Button type="submit" form="goal-money-form" disabled={add.isPending}>
          {t.common.save}
        </Button>
      </DialogFooter>
      <div className="space-y-2 border-t pt-4">
        <p className="text-sm font-semibold">{t.goals.history}</p>
        {!entries.data?.length ? (
          <p className="text-sm text-muted-foreground">{t.goals.noEntries}</p>
        ) : (
          <ul className="divide-y text-sm">
            {entries.data.map((entry) => (
              <li key={entry.id} className="flex items-center gap-3 py-2">
                <div className="min-w-0 flex-1">
                  <p className="font-medium">{entry.type === "contribution" ? t.goals.contribution : t.goals.withdrawal}</p>
                  <p className="truncate text-xs text-muted-foreground">
                    {formatDate(entry.occurred_at, locale)}
                    {entry.note ? ` · ${entry.note}` : ""}
                  </p>
                </div>
                <Amount
                  minor={entry.type === "withdrawal" ? -entry.amount_minor : entry.amount_minor}
                  currency={goal.currency}
                  tone={entry.type === "withdrawal" ? "expense" : "income"}
                  signed
                  className="font-semibold"
                />
                <Button
                  variant="ghost"
                  size="icon-sm"
                  aria-label={t.common.delete}
                  onClick={() =>
                    remove.mutate({ goalId: goal.id, entryId: entry.id }, { onError: (e) => toast.error(describeError(e, t)) })
                  }
                >
                  <Trash2 />
                </Button>
              </li>
            ))}
          </ul>
        )}
      </div>
    </>
  );
}
