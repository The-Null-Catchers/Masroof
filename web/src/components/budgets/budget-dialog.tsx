"use client";

import { Check } from "lucide-react";
import { useState, type FormEvent } from "react";
import { toast } from "sonner";

import { Field } from "@/components/common/field";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { useCategories, useMe, useSaveBudget } from "@/hooks/use-finance";
import { describeError } from "@/lib/api/describe";
import { ApiError } from "@/lib/api/errors";
import { useI18n } from "@/lib/i18n/provider";
import { CURRENCIES, currencySymbol, parseAmount, toDecimal } from "@/lib/money";
import type { Budget, BudgetPeriod } from "@/lib/types";
import { cn } from "@/lib/utils";

export function BudgetDialog({
  open,
  onOpenChange,
  budget,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  budget?: Budget | null;
}) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[92dvh] overflow-y-auto sm:max-w-lg">
        <BudgetForm budget={budget} onDone={() => onOpenChange(false)} />
      </DialogContent>
    </Dialog>
  );
}

function BudgetForm({ budget, onDone }: { budget?: Budget | null; onDone: () => void }) {
  const { t, locale, categoryLabel } = useI18n();
  const { data: me } = useMe();
  const { data: categories = [] } = useCategories();
  const save = useSaveBudget();
  const [form, setForm] = useState(() => ({
    name: budget?.name ?? "",
    period: (budget?.period ?? "monthly") as BudgetPeriod,
    currency: budget?.currency ?? me?.currency ?? "ILS",
    amount: budget?.amount ?? "",
    starts_on: budget?.starts_on ?? "",
    ends_on: budget?.ends_on ?? "",
    thresholds: (budget?.alert_thresholds ?? [50, 75, 90, 100]).join(", "),
    category_ids: budget?.category_ids ?? ([] as string[]),
  }));
  const [errors, setErrors] = useState<Record<string, string>>({});

  const expenseCategories = categories.filter((c) => c.type === "expense" && !c.parent_id && !c.archived);
  const toggle = (id: string) =>
    setForm((f) => ({
      ...f,
      category_ids: f.category_ids.includes(id) ? f.category_ids.filter((c) => c !== id) : [...f.category_ids, id],
    }));

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    const local: Record<string, string> = {};
    if (!form.name.trim()) local.name = t.common.required;
    const amount = parseAmount(form.amount, form.currency);
    if (amount === null || amount <= 0) local.amount = t.common.invalidAmount;
    const thresholds = form.thresholds
      .split(/[,،\s]+/)
      .filter(Boolean)
      .map(Number);
    if (!thresholds.length || thresholds.some((v) => !Number.isInteger(v) || v < 1 || v > 200))
      local.alert_thresholds = t.budgets.thresholdsHint;
    if (form.period === "custom" && (!form.starts_on || !form.ends_on)) local.starts_on = t.common.required;
    setErrors(local);
    if (Object.keys(local).length || amount === null) return;

    try {
      await save.mutateAsync({
        id: budget?.id,
        payload: {
          name: form.name.trim(),
          period: form.period,
          currency: form.currency,
          amount: toDecimal(amount, form.currency),
          starts_on: form.period === "custom" ? form.starts_on : null,
          ends_on: form.period === "custom" ? form.ends_on : null,
          alert_thresholds: [...new Set(thresholds)].sort((a, b) => a - b),
          category_ids: form.category_ids,
        },
      });
      toast.success(t.common.saved);
      onDone();
    } catch (e) {
      if (e instanceof ApiError && Object.keys(e.fieldErrors).length) {
        setErrors(Object.fromEntries(Object.entries(e.fieldErrors).map(([k, v]) => [k.split(".")[0], v[0]])));
      } else {
        toast.error(describeError(e, t));
      }
    }
  }

  return (
    <>
      <DialogHeader>
        <DialogTitle>{budget ? t.budgets.edit : t.budgets.add}</DialogTitle>
      </DialogHeader>
      <form id="budget-form" onSubmit={onSubmit} className="space-y-4" noValidate>
        <Field id="budget-name" label={t.budgets.name} error={errors.name}>
          <Input
            id="budget-name"
            maxLength={60}
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
            aria-invalid={!!errors.name}
          />
        </Field>
        <div className="grid gap-3 sm:grid-cols-3">
          <Field id="budget-period" label={t.budgets.period}>
            <Select value={form.period} onValueChange={(period) => setForm({ ...form, period: period as BudgetPeriod })}>
              <SelectTrigger id="budget-period" className="w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {(["monthly", "weekly", "custom"] as const).map((p) => (
                  <SelectItem key={p} value={p}>
                    {t.budgets.periods[p]}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </Field>
          <Field id="budget-currency" label={t.budgets.currency}>
            <Select value={form.currency} onValueChange={(currency) => setForm({ ...form, currency })}>
              <SelectTrigger id="budget-currency" className="w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {CURRENCIES.map((code) => (
                  <SelectItem key={code} value={code}>
                    {code} · {currencySymbol(code, locale)}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </Field>
          <Field id="budget-amount" label={t.budgets.amount} error={errors.amount}>
            <Input
              id="budget-amount"
              dir="ltr"
              inputMode="decimal"
              className="tabular"
              value={form.amount}
              onChange={(e) => setForm({ ...form, amount: e.target.value })}
              aria-invalid={!!errors.amount}
            />
          </Field>
        </div>
        {form.period === "custom" && (
          <div className="grid grid-cols-2 gap-3">
            <Field id="budget-start" label={t.budgets.startsOn} error={errors.starts_on}>
              <Input
                id="budget-start"
                type="date"
                value={form.starts_on}
                onChange={(e) => setForm({ ...form, starts_on: e.target.value })}
              />
            </Field>
            <Field id="budget-end" label={t.budgets.endsOn} error={errors.ends_on}>
              <Input
                id="budget-end"
                type="date"
                min={form.starts_on}
                value={form.ends_on}
                onChange={(e) => setForm({ ...form, ends_on: e.target.value })}
              />
            </Field>
          </div>
        )}
        <div className="space-y-1.5">
          <Label>{t.budgets.categories}</Label>
          <div className="flex flex-wrap gap-1.5">
            <button
              type="button"
              aria-pressed={form.category_ids.length === 0}
              onClick={() => setForm({ ...form, category_ids: [] })}
              className={cn(
                "rounded-full border px-3 py-1 text-xs",
                form.category_ids.length === 0 && "border-primary bg-primary/10 text-primary",
              )}
            >
              {t.budgets.allCategories}
            </button>
            {expenseCategories.map((category) => {
              const selected = form.category_ids.includes(category.id);
              return (
                <button
                  key={category.id}
                  type="button"
                  aria-pressed={selected}
                  onClick={() => toggle(category.id)}
                  className={cn(
                    "inline-flex items-center gap-1 rounded-full border px-3 py-1 text-xs",
                    selected && "border-primary bg-primary/10 text-primary",
                  )}
                >
                  {selected && <Check className="size-3" />}
                  {categoryLabel(category)}
                </button>
              );
            })}
          </div>
          {errors.category_ids && <p className="text-xs text-destructive">{errors.category_ids}</p>}
        </div>
        <Field id="budget-thresholds" label={t.budgets.thresholds} error={errors.alert_thresholds} hint={t.budgets.thresholdsHint}>
          <Input
            id="budget-thresholds"
            dir="ltr"
            value={form.thresholds}
            onChange={(e) => setForm({ ...form, thresholds: e.target.value })}
          />
        </Field>
      </form>
      <DialogFooter>
        <Button variant="outline" onClick={onDone}>
          {t.common.cancel}
        </Button>
        <Button type="submit" form="budget-form" disabled={save.isPending}>
          {save.isPending ? t.common.loading : t.common.save}
        </Button>
      </DialogFooter>
    </>
  );
}
