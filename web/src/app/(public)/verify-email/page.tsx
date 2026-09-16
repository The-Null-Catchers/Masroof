import { CircleAlert, CircleCheck } from "lucide-react";
import Link from "next/link";

import { Logo } from "@/components/brand/logo";
import { Button } from "@/components/ui/button";
import { getDictionary } from "@/lib/i18n/server";

export default async function VerifyEmailPage({ searchParams }: PageProps<"/verify-email">) {
  const t = await getDictionary();
  const verified = (await searchParams).status === "verified";
  const Icon = verified ? CircleCheck : CircleAlert;

  return (
    <div className="flex min-h-dvh flex-col items-center justify-center gap-6 px-6 text-center">
      <Logo size={48} />
      <Icon className={verified ? "size-12 text-income" : "size-12 text-destructive"} />
      <div className="space-y-2">
        <h1 className="text-2xl font-bold">{verified ? t.verify.verifiedTitle : t.verify.invalidTitle}</h1>
        <p className="max-w-sm text-muted-foreground">{verified ? t.verify.verifiedBody : t.verify.invalidBody}</p>
      </div>
      <Button asChild>
        <Link href="/">{t.verify.continue}</Link>
      </Button>
    </div>
  );
}
