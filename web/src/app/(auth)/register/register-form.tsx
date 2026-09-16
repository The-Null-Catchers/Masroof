"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState, type FormEvent } from "react";

import { isStrongPassword, PasswordInput } from "@/components/auth/password-input";
import { Field } from "@/components/common/field";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { authRequest } from "@/lib/api/client";
import { describeError } from "@/lib/api/describe";
import { ApiError } from "@/lib/api/errors";
import { useI18n } from "@/lib/i18n/provider";
import { CURRENCIES, currencySymbol } from "@/lib/money";

export function RegisterForm() {
  const { t, locale } = useI18n();
  const router = useRouter();
  const [form, setForm] = useState({ name: "", email: "", password: "", password_confirmation: "", currency: "ILS" });
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [formError, setFormError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  const set = (key: keyof typeof form) => (value: string) => setForm((f) => ({ ...f, [key]: value }));

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    const local: Record<string, string> = {};
    if (form.name.trim().length < 2) local.name = t.common.required;
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(form.email.trim())) local.email = t.common.required;
    if (!isStrongPassword(form.password)) local.password = t.auth.passwordRules;
    if (form.password !== form.password_confirmation) local.password_confirmation = t.auth.passwordsDontMatch;
    setErrors(local);
    setFormError(null);
    if (Object.keys(local).length) return;

    setPending(true);
    try {
      await authRequest("register", { ...form, name: form.name.trim(), email: form.email.trim(), locale });
      router.replace("/");
      router.refresh();
    } catch (e) {
      if (e instanceof ApiError && Object.keys(e.fieldErrors).length) {
        setErrors(Object.fromEntries(Object.entries(e.fieldErrors).map(([k, v]) => [k, v[0]])));
      } else {
        setFormError(describeError(e, t));
      }
      setPending(false);
    }
  }

  return (
    <form onSubmit={onSubmit} className="space-y-4" noValidate>
      {formError && (
        <div role="alert" className="rounded-lg border border-destructive/30 bg-destructive/10 px-3 py-2 text-sm text-destructive">
          {formError}
        </div>
      )}
      <Field id="name" label={t.auth.name} error={errors.name}>
        <Input
          id="name"
          autoComplete="name"
          value={form.name}
          onChange={(e) => set("name")(e.target.value)}
          aria-invalid={!!errors.name}
          className="h-10"
        />
      </Field>
      <Field id="email" label={t.auth.email} error={errors.email}>
        <Input
          id="email"
          type="email"
          dir="ltr"
          autoComplete="email"
          value={form.email}
          onChange={(e) => set("email")(e.target.value)}
          aria-invalid={!!errors.email}
          className="h-10"
        />
      </Field>
      <Field id="password" label={t.auth.password} error={errors.password} hint={t.auth.passwordRules}>
        <PasswordInput
          id="password"
          autoComplete="new-password"
          value={form.password}
          onChange={(e) => set("password")(e.target.value)}
          aria-invalid={!!errors.password}
        />
      </Field>
      <Field id="password_confirmation" label={t.auth.confirmPassword} error={errors.password_confirmation}>
        <PasswordInput
          id="password_confirmation"
          autoComplete="new-password"
          value={form.password_confirmation}
          onChange={(e) => set("password_confirmation")(e.target.value)}
          aria-invalid={!!errors.password_confirmation}
        />
      </Field>
      <Field id="currency" label={t.auth.currency} error={errors.currency}>
        <Select value={form.currency} onValueChange={set("currency")}>
          <SelectTrigger id="currency" className="h-10 w-full">
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
      <Button type="submit" className="h-10 w-full" disabled={pending}>
        {pending ? t.common.loading : t.auth.signUp}
      </Button>
      <p className="text-center text-sm text-muted-foreground">
        {t.auth.haveAccount}{" "}
        <Link href="/login" className="font-medium text-primary hover:underline">
          {t.auth.signIn}
        </Link>
      </p>
    </form>
  );
}
