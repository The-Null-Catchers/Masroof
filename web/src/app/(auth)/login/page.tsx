import { Suspense } from "react";

import { getDictionary } from "@/lib/i18n/server";

import { LoginForm } from "./login-form";

export async function generateMetadata() {
  return { title: (await getDictionary()).auth.signIn };
}

export default async function LoginPage() {
  const t = await getDictionary();
  return (
    <div className="space-y-8">
      <div className="space-y-2">
        <h1 className="text-2xl font-bold tracking-tight">{t.auth.loginTitle}</h1>
        <p className="text-sm text-muted-foreground">{t.auth.loginSubtitle}</p>
      </div>
      <Suspense>
        <LoginForm />
      </Suspense>
    </div>
  );
}
