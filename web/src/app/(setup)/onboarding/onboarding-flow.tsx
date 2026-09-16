"use client";

import { Check } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { toast } from "sonner";

import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { useCompleteOnboarding, useMe, type SettingsChanges } from "@/hooks/use-finance";
import { describeError } from "@/lib/api/describe";
import { useI18n } from "@/lib/i18n/provider";
import { CURRENCIES, PRIMARY_CURRENCIES, currencySymbol, parseAmount, toDecimal } from "@/lib/money";
import type { FinancialGoal, Locale } from "@/lib/types";
import { cn } from "@/lib/utils";

const STEPS = ["name", "language", "currency", "income", "goal", "alerts"] as const;
type Step = (typeof STEPS)[number];

/** Six short, skippable questions; answers are sent once at the end. */
export function OnboardingFlow() {
  const { t, locale, setLocale, format } = useI18n();
  const router = useRouter();
  const { data: me } = useMe();
  const complete = useCompleteOnboarding();
  const [index, setIndex] = useState(0);
  const [answers, setAnswers] = useState<{
    name?: string;
    locale: Locale;
    currency?: string;
    income: string;
    goal?: FinancialGoal;
    budget_alerts: boolean;
    recurring_reminders: boolean;
  }>({
    locale,
    income: "",
    budget_alerts: true,
    recurring_reminders: true,
  });
  const [incomeError, setIncomeError] = useState<string>();

  const step: Step = STEPS[index];
  const name = answers.name ?? me?.name ?? "";
  const currency = answers.currency ?? me?.currency ?? "ILS";
  const last = index === STEPS.length - 1;

  async function finish(skipRest = false) {
    const payload: SettingsChanges = {
      locale: answers.locale,
      currency,
      budget_alerts: answers.budget_alerts,
      recurring_reminders: answers.recurring_reminders,
    };
    if (name.trim().length >= 2) payload.name = name.trim();
    if (answers.goal) payload.main_goal = answers.goal;
    const income = answers.income.trim() ? parseAmount(answers.income, currency) : null;
    if (income !== null && !skipRest) payload.monthly_income_estimate = toDecimal(income, currency);
    try {
      await complete.mutateAsync(payload);
      router.replace("/");
    } catch (e) {
      toast.error(describeError(e, t));
    }
  }

  function next() {
    if (step === "income" && answers.income.trim() && parseAmount(answers.income, currency) === null) {
      return setIncomeError(t.common.invalidAmount);
    }
    setIncomeError(undefined);
    if (last) return finish();
    setIndex((i) => i + 1);
  }

  const choice = (selected: boolean) =>
    cn(
      "flex w-full items-center justify-between rounded-xl border px-4 py-3 text-start text-sm transition-colors hover:bg-muted",
      selected && "border-primary bg-primary/10 text-primary font-medium",
    );

  return (
    <Card className="gap-6 p-6 sm:p-8">
      <div className="space-y-3">
        <div className="flex items-center justify-between text-xs">
          <span className="text-muted-foreground">{format(t.onboarding.step, { current: index + 1, total: STEPS.length })}</span>
          <button type="button" className="text-primary hover:underline" onClick={() => (last ? finish(true) : setIndex((i) => i + 1))}>
            {t.onboarding.skip}
          </button>
        </div>
        <div
          className="h-1.5 overflow-hidden rounded-full bg-muted"
          role="progressbar"
          aria-valuemin={1}
          aria-valuemax={STEPS.length}
          aria-valuenow={index + 1}
        >
          <div className="h-full rounded-full bg-primary transition-all" style={{ width: `${((index + 1) / STEPS.length) * 100}%` }} />
        </div>
      </div>

      <div className="min-h-64 space-y-4">
        {step === "name" && (
          <>
            <h1 className="text-xl font-bold">{t.onboarding.nameTitle}</h1>
            <Input
              autoFocus
              value={name}
              maxLength={100}
              onChange={(e) => setAnswers({ ...answers, name: e.target.value })}
              className="h-11"
              aria-label={t.auth.name}
            />
          </>
        )}
        {step === "language" && (
          <>
            <h1 className="text-xl font-bold">{t.onboarding.languageTitle}</h1>
            {(["ar", "en"] as Locale[]).map((code) => (
              <button
                key={code}
                type="button"
                aria-pressed={answers.locale === code}
                className={choice(answers.locale === code)}
                onClick={() => {
                  setAnswers({ ...answers, locale: code });
                  setLocale(code);
                }}
              >
                {code === "ar" ? "العربية" : "English"}
                {answers.locale === code && <Check className="size-4" />}
              </button>
            ))}
          </>
        )}
        {step === "currency" && (
          <>
            <h1 className="text-xl font-bold">{t.onboarding.currencyTitle}</h1>
            <p className="text-sm text-muted-foreground">{t.onboarding.currencyBody}</p>
            <div className="grid grid-cols-2 gap-2">
              {PRIMARY_CURRENCIES.map((code) => (
                <button
                  key={code}
                  type="button"
                  aria-pressed={currency === code}
                  className={choice(currency === code)}
                  onClick={() => setAnswers({ ...answers, currency: code })}
                >
                  <span>
                    <span className="block font-semibold">{code}</span>
                    <span className="text-xs text-muted-foreground">{currencySymbol(code, locale)}</span>
                  </span>
                  {currency === code && <Check className="size-4" />}
                </button>
              ))}
            </div>
            <select
              aria-label={t.settings.currency}
              value={PRIMARY_CURRENCIES.includes(currency) ? "" : currency}
              onChange={(e) => e.target.value && setAnswers({ ...answers, currency: e.target.value })}
              className="h-10 w-full rounded-lg border border-input bg-background px-3 text-sm"
            >
              <option value="">…</option>
              {CURRENCIES.filter((c) => !PRIMARY_CURRENCIES.includes(c)).map((code) => (
                <option key={code} value={code}>
                  {code}
                </option>
              ))}
            </select>
          </>
        )}
        {step === "income" && (
          <>
            <h1 className="text-xl font-bold">{t.onboarding.incomeTitle}</h1>
            <p className="text-sm text-muted-foreground">{t.onboarding.incomeBody}</p>
            <div className="relative">
              <Input
                autoFocus
                dir="ltr"
                inputMode="decimal"
                value={answers.income}
                onChange={(e) => setAnswers({ ...answers, income: e.target.value })}
                className="tabular h-12 pe-14 text-lg"
                aria-invalid={!!incomeError}
                aria-label={t.onboarding.incomeTitle}
              />
              <span className="absolute inset-y-0 end-3 grid place-items-center text-sm text-muted-foreground">
                {currencySymbol(currency, locale)}
              </span>
            </div>
            {incomeError && <p className="text-xs text-destructive">{incomeError}</p>}
          </>
        )}
        {step === "goal" && (
          <>
            <h1 className="text-xl font-bold">{t.onboarding.goalTitle}</h1>
            <div className="grid gap-2">
              {(Object.keys(t.onboarding.goals) as FinancialGoal[]).map((goal) => (
                <button
                  key={goal}
                  type="button"
                  aria-pressed={answers.goal === goal}
                  className={choice(answers.goal === goal)}
                  onClick={() => setAnswers({ ...answers, goal })}
                >
                  {t.onboarding.goals[goal]}
                  {answers.goal === goal && <Check className="size-4" />}
                </button>
              ))}
            </div>
          </>
        )}
        {step === "alerts" && (
          <>
            <h1 className="text-xl font-bold">{t.onboarding.alertsTitle}</h1>
            {(
              [
                ["budget_alerts", t.settings.budgetAlerts, t.settings.budgetAlertsHint],
                ["recurring_reminders", t.settings.recurringReminders, t.settings.recurringRemindersHint],
              ] as const
            ).map(([key, label, hint]) => (
              <div key={key} className="flex items-center justify-between gap-4 rounded-xl border px-4 py-3">
                <div>
                  <Label htmlFor={key}>{label}</Label>
                  <p className="mt-1 text-xs text-muted-foreground">{hint}</p>
                </div>
                <Switch id={key} checked={answers[key]} onCheckedChange={(checked) => setAnswers({ ...answers, [key]: checked })} />
              </div>
            ))}
          </>
        )}
      </div>

      <div className="flex justify-between gap-3">
        <Button variant="ghost" disabled={index === 0} onClick={() => setIndex((i) => i - 1)}>
          {t.onboarding.back}
        </Button>
        <Button onClick={next} disabled={complete.isPending} className="min-w-32">
          {last ? t.onboarding.finish : t.onboarding.next}
        </Button>
      </div>
    </Card>
  );
}
