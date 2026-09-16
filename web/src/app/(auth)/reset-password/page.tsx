"use client";

import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { Suspense, useState, type FormEvent } from "react";

import { isStrongPassword, PasswordInput } from "@/components/auth/password-input";
import { Field } from "@/components/common/field";
import { Button } from "@/components/ui/button";
import { api } from "@/lib/api/client";
import { describeError } from "@/lib/api/describe";
import { useI18n } from "@/lib/i18n/provider";

function ResetForm() {
  const { t } = useI18n();
  const params = useSearchParams();
  const [password, setPassword] = useState("");
  const [confirmation, setConfirmation] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [done, setDone] = useState(false);
  const [pending, setPending] = useState(false);

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    if (!isStrongPassword(password)) return setError(t.auth.passwordRules);
    if (password !== confirmation) return setError(t.auth.passwordsDontMatch);
    setPending(true);
    setError(null);
    try {
      await api("/auth/reset-password", {
        method: "POST",
        body: { token: params.get("token"), email: params.get("email"), password, password_confirmation: confirmation },
      });
      setDone(true);
    } catch (e) {
      setError(describeError(e, t));
    } finally {
      setPending(false);
    }
  }

  if (done) {
    return (
      <div className="space-y-6">
        <p role="status" className="rounded-lg bg-primary/10 p-4 text-sm">
          {t.auth.resetDone}
        </p>
        <Button asChild className="h-10 w-full">
          <Link href="/login">{t.auth.signIn}</Link>
        </Button>
      </div>
    );
  }

  return (
    <form onSubmit={onSubmit} className="space-y-5">
      <Field id="password" label={t.settings.newPassword} error={error ?? undefined} hint={t.auth.passwordRules}>
        <PasswordInput id="password" autoComplete="new-password" value={password} onChange={(e) => setPassword(e.target.value)} />
      </Field>
      <Field id="confirmation" label={t.auth.confirmPassword}>
        <PasswordInput
          id="confirmation"
          autoComplete="new-password"
          value={confirmation}
          onChange={(e) => setConfirmation(e.target.value)}
        />
      </Field>
      <Button type="submit" className="h-10 w-full" disabled={pending}>
        {pending ? t.common.loading : t.auth.resetSubmit}
      </Button>
    </form>
  );
}

export default function ResetPasswordPage() {
  const { t } = useI18n();
  return (
    <div className="space-y-8">
      <h1 className="text-2xl font-bold tracking-tight">{t.auth.resetTitle}</h1>
      <Suspense>
        <ResetForm />
      </Suspense>
    </div>
  );
}
