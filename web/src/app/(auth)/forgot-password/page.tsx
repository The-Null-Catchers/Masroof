"use client";

import { MailCheck } from "lucide-react";
import Link from "next/link";
import { useState, type FormEvent } from "react";

import { Field } from "@/components/common/field";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { api } from "@/lib/api/client";
import { describeError } from "@/lib/api/describe";
import { useI18n } from "@/lib/i18n/provider";

export default function ForgotPasswordPage() {
  const { t } = useI18n();
  const [email, setEmail] = useState("");
  const [sent, setSent] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  async function onSubmit(event: FormEvent) {
    event.preventDefault();
    setPending(true);
    setError(null);
    try {
      await api("/auth/forgot-password", { method: "POST", body: { email: email.trim() } });
      setSent(true);
    } catch (e) {
      setError(describeError(e, t));
    } finally {
      setPending(false);
    }
  }

  return (
    <div className="space-y-8">
      <div className="space-y-2">
        <h1 className="text-2xl font-bold tracking-tight">{t.auth.forgotTitle}</h1>
        <p className="text-sm text-muted-foreground">{t.auth.forgotSubtitle}</p>
      </div>
      {sent ? (
        <div role="status" className="flex items-start gap-3 rounded-lg bg-primary/10 p-4 text-sm">
          <MailCheck className="size-5 shrink-0 text-primary" />
          {t.auth.linkSent}
        </div>
      ) : (
        <form onSubmit={onSubmit} className="space-y-5">
          <Field id="email" label={t.auth.email} error={error ?? undefined}>
            <Input id="email" type="email" dir="ltr" required value={email} onChange={(e) => setEmail(e.target.value)} className="h-10" />
          </Field>
          <Button type="submit" className="h-10 w-full" disabled={pending || !email}>
            {pending ? t.common.loading : t.auth.sendLink}
          </Button>
        </form>
      )}
      <Link href="/login" className="block text-center text-sm text-primary hover:underline">
        {t.auth.backToLogin}
      </Link>
    </div>
  );
}
