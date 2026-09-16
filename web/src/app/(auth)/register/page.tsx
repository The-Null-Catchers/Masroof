import { getDictionary } from "@/lib/i18n/server";

import { RegisterForm } from "./register-form";

export async function generateMetadata() {
  return { title: (await getDictionary()).auth.signUp };
}

export default async function RegisterPage() {
  const t = await getDictionary();
  return (
    <div className="space-y-8">
      <div className="space-y-2">
        <h1 className="text-2xl font-bold tracking-tight">{t.auth.registerTitle}</h1>
        <p className="text-sm text-muted-foreground">{t.auth.registerSubtitle}</p>
      </div>
      <RegisterForm />
    </div>
  );
}
