"use client";

import { Check } from "lucide-react";
import { useState, type FormEvent } from "react";
import { toast } from "sonner";

import { Field } from "@/components/common/field";
import { ACCOUNT_TYPE_ICONS, PALETTE } from "@/components/common/finance-icons";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import { useMe, useSaveAccount } from "@/hooks/use-finance";
import { describeError } from "@/lib/api/describe";
import { ApiError } from "@/lib/api/errors";
import { useI18n } from "@/lib/i18n/provider";
import { CURRENCIES, currencySymbol, parseAmount, toDecimal } from "@/lib/money";
import type { Account, AccountType } from "@/lib/types";
import { cn } from "@/lib/utils";

const TYPES = Object.keys(ACCOUNT_TYPE_ICONS) as AccountType[];

export function AccountDialog({
  open,
  onOpenChange,
  account,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  account?: Account | null;
}) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <AccountForm account={account} onDone={() => onOpenChange(false)} />
      </DialogContent>
    </Dialog>
  );
}

function AccountForm({ account, onDone }: { account?: Account | null; onDone: () => void }) {
  const { t, locale } = useI18n();
  const { data: me } = useMe();
  const save = useSaveAccount();
  const [form, setForm] = useState(() =>
    account
      ? {
          name: account.name,
          type: account.type,
          currency: account.currency,
          opening_balance: account.opening_balance,
          color: account.color ?? PALETTE[0],
          include_in_total: account.include_in_total,
        }
      : {
          name: "",
          type: "bank" as AccountType,
          currency: me?.currency ?? "SAR",
          opening_balance: "0",
          color: PALETTE[0],
          include_in_total: true,
        },
  );
  const [errors, setErrors] = useState<Record<string, string>>({});

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    const local: Record<string, string> = {};
    if (!form.name.trim()) local.name = t.common.required;
    const opening = parseAmount(form.opening_balance || "0", form.currency, { allowNegative: true });
    if (opening === null) local.opening_balance = t.common.invalidAmount;
    setErrors(local);
    if (Object.keys(local).length || opening === null) return;

    try {
      await save.mutateAsync({
        id: account?.id,
        payload: { ...form, name: form.name.trim(), opening_balance: toDecimal(opening, form.currency) },
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
        <DialogTitle>{account ? t.accounts.edit : t.accounts.add}</DialogTitle>
      </DialogHeader>
      <form id="account-form" onSubmit={onSubmit} className="space-y-4" noValidate>
        <Field id="account-name" label={t.accounts.name} error={errors.name}>
          <Input
            id="account-name"
            maxLength={60}
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
            aria-invalid={!!errors.name}
          />
        </Field>
        <div className="space-y-1.5">
          <Label>{t.accounts.type}</Label>
          <div className="grid grid-cols-3 gap-2">
            {TYPES.map((type) => {
              const Icon = ACCOUNT_TYPE_ICONS[type];
              return (
                <button
                  key={type}
                  type="button"
                  aria-pressed={form.type === type}
                  onClick={() => setForm({ ...form, type })}
                  className={cn(
                    "flex flex-col items-center gap-1 rounded-lg border px-2 py-2.5 text-xs transition-colors hover:bg-muted",
                    form.type === type && "border-primary bg-primary/10 text-primary",
                  )}
                >
                  <Icon className="size-4" />
                  {t.accounts.types[type]}
                </button>
              );
            })}
          </div>
        </div>
        <div className="grid grid-cols-2 gap-3">
          <Field id="account-currency" label={t.accounts.currency} error={errors.currency}>
            <Select value={form.currency} onValueChange={(currency) => setForm({ ...form, currency })}>
              <SelectTrigger id="account-currency" className="w-full">
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
          <Field id="opening" label={t.accounts.openingBalance} error={errors.opening_balance}>
            <Input
              id="opening"
              dir="ltr"
              inputMode="decimal"
              className="tabular"
              value={form.opening_balance}
              onChange={(e) => setForm({ ...form, opening_balance: e.target.value })}
              aria-invalid={!!errors.opening_balance}
            />
          </Field>
        </div>
        <div className="space-y-1.5">
          <Label>{t.accounts.color}</Label>
          <div className="flex flex-wrap gap-2">
            {PALETTE.map((color) => (
              <button
                key={color}
                type="button"
                aria-label={color}
                aria-pressed={form.color === color}
                onClick={() => setForm({ ...form, color })}
                className="grid size-8 place-items-center rounded-full ring-offset-2 transition focus-visible:ring-2"
                style={{ background: color }}
              >
                {form.color === color && <Check className="size-4 text-white" />}
              </button>
            ))}
          </div>
        </div>
        <div className="flex items-center justify-between gap-4 rounded-lg border px-3 py-2.5">
          <Label htmlFor="include-total">{t.accounts.includeInTotal}</Label>
          <Switch
            id="include-total"
            checked={form.include_in_total}
            onCheckedChange={(include_in_total) => setForm({ ...form, include_in_total })}
          />
        </div>
      </form>
      <DialogFooter>
        <Button variant="outline" onClick={onDone}>
          {t.common.cancel}
        </Button>
        <Button type="submit" form="account-form" disabled={save.isPending}>
          {save.isPending ? t.common.loading : t.common.save}
        </Button>
      </DialogFooter>
    </>
  );
}
